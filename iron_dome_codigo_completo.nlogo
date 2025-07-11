;; =====================================
;; SIMULACIÓN IRON DOME - SISTEMA DE DEFENSA ANTI-MISILES
;; Versión Final - Completamente Funcional
;; =====================================

;; VARIABLES GLOBALES
;; Gestión de estadísticas, simulación y configuración
globals [
  ; Estadísticas globales del sistema
  total-incoming-missiles      ; Contador total de misiles lanzados
  total-intercepted           ; Contador de misiles interceptados exitosamente
  total-missed               ; Contador de misiles que impactaron objetivos
  total-interceptors-fired   ; Contador de interceptores lanzados
  interception-rate          ; Porcentaje de éxito del sistema (0-100)
  
  ; Control del estado de la simulación
  simulation-running?        ; Boolean: si la simulación está activa
  last-attack-time          ; Tick del último ataque lanzado
  
  ; Configuración del entorno
  protected-zones           ; Lista de zonas bajo protección
  cities                   ; Ubicaciones de ciudades importantes
  
  ; Sistema de colas para manejo de contextos
  ; NetLogo requiere que create-* se ejecute desde observador
  pending-explosions        ; Cola de explosiones a crear
  pending-interceptors      ; Cola de interceptores a crear
  
  ; PARÁMETROS CONFIGURABLES
  ; Estos se configuran como sliders en la interfaz
  num-defense-stations      ; Número de estaciones de defensa (2-8)
  detection-range-param     ; Rango de detección radar (10-25)
  interception-range-param  ; Rango máximo de intercepción (8-20)
  reload-time-param        ; Tiempo de recarga entre disparos (5-15)
  max-interceptors-param   ; Capacidad máxima de misiles por estación
  interceptor-speed-param  ; Velocidad de interceptores (1.5-3.0)
  missile-speed            ; Velocidad de misiles atacantes (0.8-2.0)
  attack-frequency         ; Frecuencia de ataques (1-20%)
  missiles-per-attack      ; Misiles por salva (1-5)
  num-targets             ; Número de objetivos civiles (3-10)
  show-detection-ranges?   ; Mostrar rangos de detección visualmente
]

;; DEFINICIÓN DE BREEDS (TIPOS DE AGENTES)
breed [defense-stations station]    ; Estaciones Iron Dome
breed [incoming-missiles missile]   ; Misiles atacantes enemigos
breed [interceptors interceptor]    ; Misiles interceptores defensivos
breed [explosions explosion]        ; Efectos visuales de explosiones
breed [targets target]             ; Objetivos civiles a proteger

;; PROPIEDADES DE ESTACIONES DE DEFENSA
defense-stations-own [
  detection-range           ; Rango del radar (copiado del parámetro global)
  interception-range       ; Rango máximo de misiles interceptores
  reload-time             ; Tiempo mínimo entre disparos consecutivos
  operational?           ; Estado: true=funcional, false=dañada
  targets-tracked        ; Lista de misiles que esta estación rastrea
]

;; PROPIEDADES DE MISILES ATACANTES
incoming-missiles-own [
  target-x               ; Coordenada X del objetivo seleccionado
  target-y               ; Coordenada Y del objetivo seleccionado
  speed                 ; Velocidad de vuelo del misil
  altitude              ; Altitud simulada (decrece con el tiempo)
  launch-time           ; Tick en que fue lanzado
  detected?             ; Boolean: si ha sido detectado por radar
  tracking-stations     ; Lista de estaciones que lo rastrean
  trajectory-angle      ; Ángulo de vuelo hacia el objetivo
  fuel                 ; Combustible restante (decrece con el tiempo)
]

;; PROPIEDADES DE INTERCEPTORES
interceptors-own [
  target-missile-id     ; Referencia al misil que persigue
  interceptor-speed     ; Velocidad de persecución
  fuel                 ; Combustible limitado
  launch-station       ; Referencia a la estación que lo lanzó
  intercept-range      ; Distancia a la que detona (proximidad)
]

;; PROPIEDADES DE EXPLOSIONES (EFECTOS VISUALES)
explosions-own [
  explosion-time        ; Tiempo de vida restante
  explosion-type       ; "impact" (impacto) o "intercept" (intercepción)
]

;; PROPIEDADES DE OBJETIVOS CIVILES
targets-own [
  population           ; Número de habitantes (10k-100k)
  importance          ; Importancia estratégica (1-5)
  protected?          ; Si está actualmente protegido
]

;; =====================================
;; PROCEDIMIENTOS DE INICIALIZACIÓN
;; =====================================

;; PROCEDIMIENTO PRINCIPAL DE CONFIGURACIÓN
to setup
  clear-all
  
  ; Inicializar parámetros por defecto
  ; En la interfaz real, estos valores vienen de los sliders
  set num-defense-stations 4
  set detection-range-param 15
  set interception-range-param 12
  set reload-time-param 8
  set max-interceptors-param 20
  set interceptor-speed-param 2.5
  set missile-speed 1.2
  set attack-frequency 8
  set missiles-per-attack 2
  set num-targets 6
  set show-detection-ranges? true
  
  ; Configurar el entorno de simulación
  setup-terrain
  setup-defense-stations
  setup-targets
  
  ; Inicializar sistema
  reset-statistics
  setup-visualization
  
  reset-ticks
end

;; CONFIGURACIÓN DEL TERRENO
to setup-terrain
  ; Crear terreno realista con colores suaves para mejor visibilidad
  ask patches [
    ; Territorio dividido por la línea y=0
    ifelse pycor > 0 [
      ; Territorio defendido (zona verde suave)
      set pcolor scale-color green random 30 0 50
    ][
      ; Territorio hostil (zona marrón suave)
      set pcolor scale-color brown random 30 0 50
    ]
  ]
  
  ; Marcar la frontera con color menos intenso
  ask patches with [pycor = 0] [
    set pcolor red - 2
  ]
end

;; CONFIGURACIÓN DE ESTACIONES DE DEFENSA
to setup-defense-stations
  ; Distribución estratégica de estaciones
  let station-count num-defense-stations
  let spacing world-width / (station-count + 1)
  
  create-defense-stations station-count [
    ; Posicionamiento equidistante en territorio defendido
    let station-x (who - min [who] of defense-stations + 1) * spacing - world-width / 2
    setxy station-x (random 8 + 5)
    
    ; Configuración visual
    set shape "house"
    set color blue + 1  ; Azul brillante para visibilidad
    set size 2
    
    ; Configuración operacional
    set detection-range detection-range-param
    set interception-range interception-range-param
    set reload-time reload-time-param
    set operational? true
    set targets-tracked []
    
    ; Mostrar rango de detección si está activado
    if show-detection-ranges? [
      ask patches in-radius detection-range [
        if pcolor != (red - 2) [ 
          set pcolor pcolor + 0.5  ; Efecto sutil
        ]
      ]
    ]
  ]
end

;; CONFIGURACIÓN DE OBJETIVOS CIVILES
to setup-targets
  ; Crear ciudades y objetivos importantes en territorio defendido
  create-targets num-targets [
    setxy random-xcor (random 10 + 5)
    
    ; Configuración visual
    set shape "circle"
    set color white
    set size 1.5
    
    ; Propiedades demográficas y estratégicas
    set population (random 90000 + 10000)  ; 10k-100k habitantes
    set importance (random 5 + 1)           ; Importancia 1-5
    set protected? false
  ]
end

;; CONFIGURACIÓN INICIAL DE VISUALIZACIÓN
to setup-visualization
  set simulation-running? false
  set last-attack-time 0
end

;; REINICIO DE ESTADÍSTICAS
to reset-statistics
  set total-incoming-missiles 0
  set total-intercepted 0
  set total-missed 0
  set total-interceptors-fired 0
  set interception-rate 0
  set pending-explosions []
  set pending-interceptors []
end

;; =====================================
;; BUCLE PRINCIPAL DE SIMULACIÓN
;; =====================================

;; PROCEDIMIENTO PRINCIPAL DE EJECUCIÓN
to go
  ifelse not simulation-running? [
    set simulation-running? true
  ][
    ; Gestión de ataques aleatorios
    if should-launch-attack? [
      launch-missile-attack
    ]
    
    ; Actualización de todos los agentes
    update-defense-stations
    update-incoming-missiles
    update-interceptors
    update-explosions
    
    ; Procesamiento de colas (gestión de contextos)
    create-pending-interceptors
    create-pending-explosions
    
    ; Mantenimiento del sistema
    update-statistics
    cleanup-agents
  ]
  
  tick
end

;; DETERMINACIÓN DE ATAQUES ALEATORIOS
to-report should-launch-attack?
  let time-since-last-attack ticks - last-attack-time
  let attack-probability attack-frequency / 100
  
  ; Requiere tiempo mínimo entre ataques Y probabilidad
  report (time-since-last-attack > 10) and (random-float 1 < attack-probability)
end

;; =====================================
;; SISTEMA DE ATAQUES
;; =====================================

;; LANZAMIENTO DE ATAQUE CON MISILES
to launch-missile-attack
  let num-missiles (random missiles-per-attack + 1)
  
  repeat num-missiles [
    create-incoming-missiles 1 [
      ; Posición de lanzamiento en territorio hostil
      setxy (random world-width - world-width / 2) (random 8 - 15)
      
      ; Selección aleatoria de objetivo civil
      let chosen-target one-of targets
      if chosen-target != nobody [
        set target-x [xcor] of chosen-target
        set target-y [ycor] of chosen-target
      ]
      
      ; Configuración del misil
      set shape "airplane"
      set color red + 1     ; Rojo brillante para visibilidad
      set size 1.2          ; Tamaño aumentado para visibilidad
      set speed missile-speed
      set altitude (random 50 + 50)
      set launch-time ticks
      set detected? false
      set tracking-stations []
      set fuel 100
      
      ; Cálculo de trayectoria hacia objetivo
      set trajectory-angle towardsxy target-x target-y
      set heading trajectory-angle
      
      set total-incoming-missiles total-incoming-missiles + 1
    ]
  ]
  
  set last-attack-time ticks
end

;; =====================================
;; SISTEMA DE DEFENSA
;; =====================================

;; ACTUALIZACIÓN DE ESTACIONES DE DEFENSA
to update-defense-stations
  ask defense-stations [
    if operational? [
      detect-incoming-missiles  ; Escaneo radar
      decide-interception      ; Análisis y decisión de disparo
    ]
  ]
end

;; DETECCIÓN RADAR DE MISILES
;; Ejecutado por cada estación individual
to detect-incoming-missiles
  let nearby-missiles incoming-missiles in-radius detection-range
  
  ask nearby-missiles [
    if not detected? [
      set detected? true
      set color orange + 1  ; Cambio visual al ser detectado
      
      ; Añadir a la lista de rastreados de esta estación
      ask myself [
        set targets-tracked lput myself targets-tracked
      ]
    ]
  ]
end

;; LÓGICA DE DECISIÓN DE INTERCEPCIÓN
;; Ejecutado por cada estación individual
to decide-interception
  if operational? [
    let threat-missile find-highest-threat
    
    if threat-missile != nobody [
      ; Cálculos balísticos para determinar factibilidad
      let distance-to-threat distancexy ([xcor] of threat-missile) ([ycor] of threat-missile)
      let time-to-intercept distance-to-threat / interceptor-speed-param
      let missile-distance-to-target [distancexy target-x target-y] of threat-missile
      let missile-time-to-target missile-distance-to-target / [speed] of threat-missile
      
      ; Decidir intercepción basado en factibilidad temporal y espacial
      if time-to-intercept <= missile-time-to-target and distance-to-threat <= interception-range [
        ; Añadir interceptor a cola para creación desde observador
        let station-x xcor
        let station-y ycor
        set pending-interceptors lput (list station-x station-y threat-missile who) pending-interceptors
        
        ; Remover de lista para evitar disparos múltiples
        set targets-tracked remove threat-missile targets-tracked
      ]
    ]
  ]
end

;; ALGORITMO DE PRIORIZACIÓN DE AMENAZAS
;; Ejecutado por cada estación individual
to-report find-highest-threat
  let tracked-missiles incoming-missiles with [member? self [targets-tracked] of myself]
  
  ifelse any? tracked-missiles [
    ; Priorizar por proximidad al impacto (misil más cerca de su objetivo)
    report min-one-of tracked-missiles [
      distancexy target-x target-y
    ]
  ][
    report nobody
  ]
end

;; =====================================
;; SISTEMA DE MISILES
;; =====================================

;; ACTUALIZACIÓN DE MISILES ATACANTES
to update-incoming-missiles
  ask incoming-missiles [
    ; Cálculo de distancia al objetivo
    let ddx (target-x - xcor)
    let dyy (target-y - ycor)
    let distance-to-target sqrt (ddx * ddx + dyy * dyy)
    
    ifelse distance-to-target > 0.5 [
      ; Continuar vuelo hacia objetivo
      let move-distance speed
      set heading towardsxy target-x target-y
      fd move-distance
      
      ; Consumo de recursos
      set fuel fuel - 1
      set altitude altitude - 0.5
    ][
      ; Impacto en objetivo
      missile-impact
    ]
    
    ; Destrucción por agotamiento de combustible
    if fuel <= 0 [ die ]
  ]
end

;; PROCEDIMIENTO DE IMPACTO DE MISIL
;; Ejecutado por misil individual al llegar a destino
to missile-impact
  ; Guardar coordenadas antes de morir
  let missile-x xcor
  let missile-y ycor
  
  ; Registrar impacto en estadísticas
  set total-missed total-missed + 1
  
  ; Afectar objetivo civil cercano
  let nearby-target min-one-of targets [distancexy missile-x missile-y]
  if nearby-target != nobody and [distancexy missile-x missile-y] of nearby-target < 3 [
    ask nearby-target [
      set color red
      set protected? false
    ]
  ]
  
  ; Añadir explosión a cola para creación
  set pending-explosions lput (list missile-x missile-y "impact") pending-explosions
  
  die
end

;; =====================================
;; SISTEMA DE INTERCEPTORES
;; =====================================

;; ACTUALIZACIÓN DE INTERCEPTORES
to update-interceptors
  ask interceptors [
    ifelse target-missile-id != nobody [
      ; Persecución activa del objetivo
      face target-missile-id
      fd interceptor-speed
      
      ; Verificación de intercepción por proximidad
      let distance-to-target distancexy ([xcor] of target-missile-id) ([ycor] of target-missile-id)
      if distance-to-target < intercept-range [
        ; Intercepción exitosa
        let intercept-x xcor
        let intercept-y ycor
        
        ; Añadir explosión de intercepción a cola
        set pending-explosions lput (list intercept-x intercept-y "intercept") pending-explosions
        
        ; Destruir misil objetivo y registrar éxito
        ask target-missile-id [
          set total-intercepted total-intercepted + 1
          die
        ]
        
        die
      ]
      
      ; Consumo de combustible
      set fuel fuel - 2
      if fuel <= 0 [ die ]
    ][
      ; Objetivo perdido o destruido
      die
    ]
  ]
end

;; =====================================
;; SISTEMA DE EFECTOS VISUALES
;; =====================================

;; ACTUALIZACIÓN DE EXPLOSIONES
to update-explosions
  ask explosions [
    set explosion-time explosion-time - 1
    set size size - 0.1
    
    ; Destrucción al final del ciclo de vida
    if explosion-time <= 0 or size <= 0 [
      die
    ]
  ]
end

;; =====================================
;; GESTIÓN DE CONTEXTOS (SISTEMA DE COLAS)
;; =====================================

;; CREACIÓN DE INTERCEPTORES PENDIENTES
;; Ejecutado desde contexto observador
to create-pending-interceptors
  foreach pending-interceptors [ interceptor-data ->
    let station-x item 0 interceptor-data
    let station-y item 1 interceptor-data
    let target-missile item 2 interceptor-data
    let launch-station-id item 3 interceptor-data
    
    ; Verificar que el objetivo aún existe
    if target-missile != nobody [
      create-interceptors 1 [
        setxy station-x station-y
        set shape "arrow"
        set color green
        set size 0.8
        set target-missile-id target-missile
        set interceptor-speed interceptor-speed-param
        set fuel 100
        set launch-station turtle launch-station-id
        set intercept-range 2
        
        ; Orientación inicial hacia objetivo
        face target-missile
      ]
      
      set total-interceptors-fired total-interceptors-fired + 1
    ]
  ]
  
  ; Limpiar cola
  set pending-interceptors []
end

;; CREACIÓN DE EXPLOSIONES PENDIENTES
;; Ejecutado desde contexto observador
to create-pending-explosions
  foreach pending-explosions [ explosion-data ->
    let exp-x item 0 explosion-data
    let exp-y item 1 explosion-data
    let exp-type item 2 explosion-data
    
    create-explosions 1 [
      setxy exp-x exp-y
      set explosion-time ifelse-value (exp-type = "impact") [10] [8]
      set explosion-type exp-type
      set size ifelse-value (exp-type = "impact") [3] [2]
      
      ; Diferenciación visual por tipo
      ifelse exp-type = "impact" [
        set shape "circle"
        set color red + 2
      ][
        set shape "star"
        set color yellow
      ]
    ]
  ]
  
  ; Limpiar cola
  set pending-explosions []
end

;; =====================================
;; MANTENIMIENTO DEL SISTEMA
;; =====================================

;; ACTUALIZACIÓN DE ESTADÍSTICAS
to update-statistics
  if total-incoming-missiles > 0 [
    set interception-rate (total-intercepted / total-incoming-missiles) * 100
  ]
end

;; LIMPIEZA DE AGENTES FUERA DE LÍMITES
to cleanup-agents
  ; Eliminar misiles que salieron del mundo
  ask incoming-missiles [
    if xcor < min-pxcor or xcor > max-pxcor or ycor < min-pycor or ycor > max-pycor [
      die
    ]
  ]
  
  ; Eliminar interceptores que salieron del mundo
  ask interceptors [
    if xcor < min-pxcor or xcor > max-pxcor or ycor < min-pycor or ycor > max-pycor [
      die
    ]
  ]
end

;; =====================================
;; PROCEDIMIENTOS DE CONTROL
;; =====================================

;; LANZAMIENTO DE ATAQUE DE EMERGENCIA (PARA PRUEBAS)
to emergency-launch-attack
  repeat 5 [
    launch-missile-attack
  ]
end

;; SIMULACIÓN DE DAÑO A ESTACIÓN
to disable-random-station
  if any? defense-stations [
    ask one-of defense-stations [
      set operational? false
      set color gray
    ]
  ]
end

;; REPARACIÓN DE TODAS LAS ESTACIONES
to repair-all-stations
  ask defense-stations [
    set operational? true
    set color blue + 1
  ]
end

;; =====================================
;; REPORTADORES PARA LA INTERFAZ
;; =====================================

;; TASA DE ÉXITO DEL SISTEMA
to-report success-rate
  report precision interception-rate 1
end

;; NÚMERO DE AMENAZAS ACTIVAS
to-report active-threats
  report count incoming-missiles
end

;; INTERCEPTORES EN VUELO
to-report interceptors-in-flight
  report count interceptors
end

;; ESTACIONES OPERACIONALES
to-report stations-operational
  report count defense-stations with [operational?]
end

;; MUNICIÓN PROMEDIO (SIMPLIFICADO)
to-report average-station-ammo
  ; Sistema simplificado con munición infinita
  let operational-count count defense-stations with [operational?]
  ifelse operational-count > 0 [
    report 100  ; Munición infinita
  ][
    report 0
  ]
end

;; NIVEL DE AMENAZA CATEGORIZADO
to-report threat-level
  let threats active-threats
  if threats = 0 [ report "BAJO" ]
  if threats <= 3 [ report "MEDIO" ]
  if threats <= 6 [ report "ALTO" ]
  report "CRÍTICO"
end

;; ANÁLISIS DE PROTECCIÓN TERRITORIAL
to-report zone-protection-analysis
  let protected-count count targets with [protected?]
  let total-targets count targets
  ifelse total-targets > 0 [
    report precision ((protected-count / total-targets) * 100) 1
  ][
    report 0
  ]
end

;; =====================================
;; FIN DEL CÓDIGO
;; =====================================
