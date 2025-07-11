globals [
  ; Estadísticas globales
  total-incoming-missiles      ; total de misiles lanzados
  total-intercepted           ; total de misiles interceptados
  total-missed               ; total de misiles que impactaron
  total-interceptors-fired   ; total de interceptores lanzados
  interception-rate          ; tasa de éxito

  ; Control de simulación
  simulation-running?        ; estado de la simulación
  last-attack-time          ; tiempo del último ataque

  ; Configuraciones del terreno
  protected-zones           ; lista de zonas protegidas
  cities                   ; ubicaciones de ciudades

  ; Cola de explosiones e interceptores pendientes
  pending-explosions        ; lista de explosiones a crear
  pending-interceptors      ; lista de interceptores a crear

  ; Parámetros configurables (normalmente serían sliders)
  ;num-defense-stations      ; número de estaciones de defensa
  ;detection-range-param     ; rango de detección
  ;interception-range-param  ; rango de intercepción
  ;reload-time-param        ; tiempo de recarga
  max-interceptors-param   ; máximo de interceptores por estación
  ;interceptor-speed-param  ; velocidad de interceptores
  ;missile-speed            ; velocidad de misiles atacantes
  ;attack-frequency         ; frecuencia de ataques
  ;missiles-per-attack      ; misiles por ataque
  ;num-targets             ; número de objetivos
  ;show-detection-ranges?   ; mostrar rangos de detección
]

breed [defense-stations station]    ; Estaciones de defensa
breed [incoming-missiles missile]   ; Misiles atacantes
breed [interceptors interceptor]    ; Misiles interceptores
breed [explosions explosion]        ; Efectos de explosión
breed [targets target]             ; Objetivos a proteger

; Propiedades de las estaciones de defensa
defense-stations-own [
  detection-range           ; rango de detección
  interception-range       ; rango de intercepción
  reload-time             ; tiempo de recarga
  operational?           ; estado operacional
  targets-tracked        ; lista de misiles rastreados
]

; Propiedades de los misiles atacantes
incoming-missiles-own [
  target-x               ; coordenada x del objetivo
  target-y               ; coordenada y del objetivo
  speed                 ; velocidad del misil
  altitude              ; altitud simulada
  launch-time           ; tiempo de lanzamiento
  detected?             ; si ha sido detectado
  tracking-stations     ; estaciones que lo rastrean
  trajectory-angle      ; ángulo de trayectoria
  fuel                 ; combustible restante
]

; Propiedades de los interceptores
interceptors-own [
  target-missile-id     ; misil objetivo
  interceptor-speed     ; velocidad del interceptor
  fuel                 ; combustible
  launch-station       ; estación que lo lanzó
  intercept-range      ; rango de intercepción
]

; Propiedades de explosiones
explosions-own [
  explosion-time        ; tiempo de vida de la explosión
  explosion-type       ; tipo: intercepción o impacto
]

; Propiedades de objetivos
targets-own [
  population           ; población del objetivo
  importance          ; importancia estratégica
  protected?          ; si está protegido
]

to setup
  clear-all

  ; Inicializar parámetros por defecto (normalmente serían sliders)


  ; Configurar el terreno
  setup-terrain

  ; Crear estaciones de defensa
  setup-defense-stations

  ; Crear objetivos a proteger
  setup-targets

  ; Inicializar estadísticas
  reset-statistics

  ; Configurar visualización
  setup-visualization

  reset-ticks
end

to setup-terrain
  ; Crear un terreno realista con colores más suaves
  ask patches [
    ; Simular diferentes tipos de terreno con colores menos intensos
    ifelse pycor > 0 [
      set pcolor scale-color green random 30 0 50  ; Verde más suave - territorio defendido
    ][
      set pcolor scale-color brown random 30 0 50  ; Marrón más suave - territorio hostil
    ]
  ]

  ; Marcar la frontera con color más tenue
  ask patches with [pycor = 0] [
    set pcolor red - 2  ; Rojo menos intenso
  ]
end

to setup-defense-stations
  ; Crear estaciones de defensa distribuidas estratégicamente
  let station-count num-defense-stations
  let spacing world-width / (station-count + 1)

  create-defense-stations station-count [
    ; Posicionar estaciones
    let station-x (who - min [who] of defense-stations + 1) * spacing - world-width / 2
    setxy station-x (random 8 + 5)  ; En territorio defendido

    ; Configurar propiedades
    set shape "house"
    set color blue + 1  ; Azul más brillante para mejor visibilidad
    set size 2

    ; Parámetros configurables
    set detection-range detection-range-param
    set interception-range interception-range-param
    set reload-time reload-time-param
    set operational? true
    set targets-tracked []

    ; Mostrar rango de detección con color muy sutil
    if show-detection-ranges? [
      ask patches in-radius detection-range [
        if pcolor != (red - 2) [ set pcolor pcolor + 1 ]  ; Efecto muy sutil
      ]
    ]
  ]
end

to setup-targets
  ; Crear ciudades y objetivos importantes
  create-targets num-targets [
    setxy random-xcor (random 10 + 5)  ; En territorio defendido
    set shape "circle"
    set color white
    set size 1.5
    set population (random 90000 + 10000)  ; 10k-100k habitantes
    set importance (random 5 + 1)           ; Importancia 1-5
    set protected? false
  ]
end

to setup-visualization
  ; Configurar la visualización inicial
  set simulation-running? false
  set last-attack-time 0
end

to reset-statistics
  set total-incoming-missiles 0
  set total-intercepted 0
  set total-missed 0
  set total-interceptors-fired 0
  set interception-rate 0
  set pending-explosions []
  set pending-interceptors []
end

to go

  ifelse not simulation-running? [
    set simulation-running? true
  ][
    ; Generar ataques aleatorios
    if should-launch-attack? [
      launch-missile-attack
    ]

    ; Actualizar todos los agentes
    update-defense-stations
    update-incoming-missiles
    update-interceptors
    update-explosions

    ; Crear interceptores y explosiones pendientes desde el observador
    create-pending-interceptors
    create-pending-explosions

    ; Actualizar estadísticas
    update-statistics

    ; Limpiar agentes destruidos
    cleanup-agents
  ]

  tick
end

to-report should-launch-attack?
  ; Determinar si debe ocurrir un ataque
  let time-since-last-attack ticks - last-attack-time
  let attack-probability attack-frequency / 100

  report (time-since-last-attack > 10) and (random-float 1 < attack-probability)
end

to launch-missile-attack
  ; Lanzar uno o más misiles
  let num-missiles (random missiles-per-attack + 1)

  repeat num-missiles [
    create-incoming-missiles 1 [
      ; Posición de lanzamiento (territorio hostil)
      setxy (random world-width - world-width / 2) (random 8 - 15)

      ; Seleccionar objetivo
      let chosen-target one-of targets
      if chosen-target != nobody [
        set target-x [xcor] of chosen-target
        set target-y [ycor] of chosen-target
      ]

      ; Configurar propiedades del misil
      set shape "airplane"
      set color red + 4  ; Rojo más brillante para mejor visibilidad
      set size 1.2      ; Tamaño ligeramente mayor
      set speed missile-speed
      set altitude (random 50 + 50)  ; Altitud inicial
      set launch-time ticks
      set detected? false
      set tracking-stations []
      set fuel 100

      ; Calcular trayectoria
      set trajectory-angle towardsxy target-x target-y
      set heading trajectory-angle

      set total-incoming-missiles total-incoming-missiles + 1
    ]
  ]

  set last-attack-time ticks
end

to update-defense-stations
  ask defense-stations [
    if operational? [
      ; Detectar misiles entrantes
      detect-incoming-missiles

      ; Decidir si interceptar
      decide-interception
    ]
  ]
end

to detect-incoming-missiles  ; procedimiento de station
  let nearby-missiles incoming-missiles in-radius detection-range

  ask nearby-missiles [
    if not detected? [
      set detected? true
      set color orange + 1  ; Naranja más brillante cuando detectado

      ; Añadir a la lista de objetivos rastreados
      ask myself [
        set targets-tracked lput myself targets-tracked
      ]
    ]
  ]
end

to decide-interception  ; procedimiento de station
  ; Solo si la estación está operacional
  if operational? [

    ; Buscar el misil más amenazante
    let threat-missile find-highest-threat

    if threat-missile != nobody [
      ; Calcular si puede interceptar
      let distance-to-threat distancexy ([xcor] of threat-missile) ([ycor] of threat-missile)
      let time-to-intercept distance-to-threat / interceptor-speed-param
      let missile-distance-to-target [distancexy target-x target-y] of threat-missile
      let missile-time-to-target missile-distance-to-target / [speed] of threat-missile

      ; Interceptar si es factible (condiciones más permisivas)
      if time-to-intercept <= missile-time-to-target and distance-to-threat <= interception-range [
        ; Añadir interceptor a cola para crear desde observador
        let station-x xcor
        let station-y ycor
        set pending-interceptors lput (list station-x station-y threat-missile who) pending-interceptors

        ; Remover el misil de la lista de rastreados para evitar disparos múltiples
        set targets-tracked remove threat-missile targets-tracked
      ]
    ]
  ]
end

to-report find-highest-threat  ; reporter de station
  let tracked-missiles incoming-missiles with [member? self [targets-tracked] of myself]

  ifelse any? tracked-missiles [
    ; Priorizar por proximidad a objetivos importantes
    ; Simplificar usando solo distancia al objetivo del misil
    report min-one-of tracked-missiles [
      distancexy target-x target-y
    ]
  ][
    report nobody
  ]
end

to cleanup-agents
  ; Limpiar agentes que salieron del mundo
  ask incoming-missiles [
    if xcor < min-pxcor or xcor > max-pxcor or ycor < min-pycor or ycor > max-pycor [
      die
    ]
  ]

  ask interceptors [
    if xcor < min-pxcor or xcor > max-pxcor or ycor < min-pycor or ycor > max-pycor [
      die
    ]
  ]
end



to update-incoming-missiles
  ask incoming-missiles [
    ; Mover hacia el objetivo
    let ddx (target-x - xcor)
    let dyy (target-y - ycor)
    let distance-to-target sqrt (ddx * ddx + dyy * dyy)

    ifelse distance-to-target >= 0.6 [
      ; Continuar movimiento
      let move-distance speed
      set heading towardsxy target-x target-y
      fd move-distance

      ; Consumir combustible
      set fuel fuel - 1

      ; Simular degradación de altitud
      set altitude altitude - 0.5
    ][
      ; Impacto en objetivo
      missile-impact
    ]

    ; Destruir si se queda sin combustible
    if fuel <= 0 [
      die
    ]
  ]
end

to missile-impact  ; procedimiento de missile
  ; Guardar coordenadas del misil antes de morir
  let missile-x xcor
  let missile-y ycor

  ; Registrar impacto
  set total-missed total-missed + 1

  ; Afectar objetivo cercano
  let nearby-target min-one-of targets [distancexy missile-x missile-y]
  if nearby-target != nobody and [distancexy missile-x missile-y] of nearby-target < 3 [
    ask nearby-target [
      set color red
      set protected? false
    ]
  ]

  ; Añadir explosión a la cola para crear desde el observador
  set pending-explosions lput (list missile-x missile-y "impact") pending-explosions

  die
end

to update-interceptors
  ask interceptors [
    ifelse target-missile-id != nobody [
      ; Perseguir el misil objetivo
      face target-missile-id
      fd interceptor-speed

      ; Verificar intercepción usando distancexy
      let distance-to-target distancexy ([xcor] of target-missile-id) ([ycor] of target-missile-id)
      if distance-to-target < intercept-range [
        ; Guardar coordenadas para la explosión
        let intercept-x xcor
        let intercept-y ycor

        ; Añadir explosión a la cola
        set pending-explosions lput (list intercept-x intercept-y "intercept") pending-explosions

        ask target-missile-id [
          set total-intercepted total-intercepted + 1
          die
        ]

        die
      ]

      ; Consumir combustible
      set fuel fuel - 2
      if fuel <= 0 [ die ]
    ][
      ; Si el objetivo fue destruido, autodestruirse
      die
    ]
  ]
end

to update-explosions
  ask explosions [
    set explosion-time explosion-time - 1
    set size size - 0.1

    if explosion-time <= 0 or size <= 0 [
      die
    ]
  ]
end

to update-statistics
  if total-incoming-missiles > 0 [
    set interception-rate (total-intercepted / total-incoming-missiles) * 100
  ]
end

to create-pending-interceptors
  ; Crear todos los interceptores pendientes desde el contexto del observador
  foreach pending-interceptors [ interceptor-data ->
    let station-x item 0 interceptor-data
    let station-y item 1 interceptor-data
    let target-missile item 2 interceptor-data
    let launch-station-id item 3 interceptor-data

    ; Verificar que el misil objetivo sigue existiendo
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

        ; Dirigir hacia el misil objetivo
        face target-missile
      ]

      ; Actualizar estadísticas globales
      set total-interceptors-fired total-interceptors-fired + 1
    ]
  ]

  ; Limpiar la cola de interceptores
  set pending-interceptors []
end

to create-pending-explosions
  ; Crear todas las explosiones pendientes desde el contexto del observador
  foreach pending-explosions [ explosion-data ->
    let exp-x item 0 explosion-data
    let exp-y item 1 explosion-data
    let exp-type item 2 explosion-data

    create-explosions 1 [
      setxy exp-x exp-y
      set explosion-time ifelse-value (exp-type = "impact") [10] [8]
      set explosion-type exp-type
      set size ifelse-value (exp-type = "impact") [3] [2]

      ifelse exp-type = "impact" [
        set shape "circle"
        set color red + 2
      ][
        set shape "star"
        set color yellow
      ]
    ]
  ]

  ; Limpiar la cola de explosiones
  set pending-explosions []
end

; Procedimientos de control
to start-simulation
  set simulation-running? true
end

to stop-simulation
  set simulation-running? false
end

to emergency-launch-attack
  ; Lanzar ataque masivo para pruebas
  repeat 5 [
    launch-missile-attack
  ]
end

to disable-random-station
  ; Simular daño a estación aleatoria
  if any? defense-stations [
    ask one-of defense-stations [
      set operational? false
      set color gray
    ]
  ]
end

to repair-all-stations
  ; Reparar todas las estaciones
  ask defense-stations [
    set operational? true
    set color blue
  ]
end

; Reportadores para la interfaz
to-report success-rate
  report precision interception-rate 1
end

to-report active-threats
  report count incoming-missiles
end

to-report interceptors-in-flight
  report count interceptors
end

to-report stations-operational
  report count defense-stations with [operational?]
end

to-report average-station-ammo
  ; Sistema simplificado - las estaciones siempre tienen munición disponible
  ; Solo reportar si están operacionales
  let operational-count count defense-stations with [operational?]
  ifelse operational-count > 0 [
    report 100  ; Munición infinita
  ][
    report 0
  ]
end

to-report threat-level
  let threats active-threats
  if threats = 0 [ report "BAJO" ]
  if threats <= 3 [ report "MEDIO" ]
  if threats <= 6 [ report "ALTO" ]
  report "CRÍTICO"
end

; Análisis de efectividad por zona
to-report zone-protection-analysis
  let protected-count count targets with [protected?]
  let total-targets count targets
  ifelse total-targets > 0 [
    report precision ((protected-count / total-targets) * 100) 1
  ][
    report 0
  ]
end

; PARÁMETROS CONFIGURABLES (agregar como sliders en la interfaz)
; num-defense-stations: 3-8 estaciones
; detection-range-param: 10-25 unidades
; interception-range-param: 8-20 unidades
; reload-time-param: 5-15 ticks
; max-interceptors-param: 10-30 misiles
; interceptor-speed-param: 1.5-3.0 unidades/tick
; missile-speed: 0.8-2.0 unidades/tick
; attack-frequency: 1-20 (probabilidad por tick)
; missiles-per-attack: 1-5 misiles
; num-targets: 3-10 objetivos
; show-detection-ranges?: true/false

; SWITCHES RECOMENDADOS:
; show-detection-ranges?

; MONITORES RECOMENDADOS:
; success-rate
; active-threats
; interceptors-in-flight
; stations-operational
; average-station-ammo
; threat-level
; total-incoming-missiles
; total-intercepted
; total-missed

; BOTONES RECOMENDADOS:
; setup
; go (forever)
; start-simulation
; stop-simulation
; emergency-launch-attack
; disable-random-station
; repair-all-stations
; reset-statistics
@#$#@#$#@
GRAPHICS-WINDOW
245
10
619
385
-1
-1
10.46
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
25
85
92
118
SETUP
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
125
197
158
ATAQUE MASIVO
emergency-launch-attack
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
85
197
118
GO/STOP
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
210
212
243
DAÑAR ESTACIÓN
disable-random-station
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
255
217
288
REPARAR TODO
repair-all-stations
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
645
10
830
43
num-defense-stations
num-defense-stations
0
8
7.0
1
1
NIL
HORIZONTAL

SLIDER
645
55
830
88
detection-range-param
detection-range-param
10
25
12.0
1
1
NIL
HORIZONTAL

SLIDER
645
100
832
133
interception-range-param
interception-range-param
8
20
13.0
1
1
NIL
HORIZONTAL

SLIDER
645
145
830
178
reload-time-param
reload-time-param
5
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
645
280
837
313
interceptor-speed-param
interceptor-speed-param
1.5
3
2.5
0.1
1
NIL
HORIZONTAL

SLIDER
645
330
817
363
missile-speed
missile-speed
0.8
2
1.3
0.1
1
NIL
HORIZONTAL

SLIDER
895
45
1067
78
attack-frequency
attack-frequency
1
20
14.0
1
1
NIL
HORIZONTAL

SLIDER
895
90
1067
123
missiles-per-attack
missiles-per-attack
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
895
135
1067
168
num-targets
num-targets
3
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
499
415
616
460
Tasa de Éxito (%)
success-rate
1
1
11

MONITOR
499
475
616
520
Amenazas Activas
active-threats
0
1
11

MONITOR
629
415
771
460
Interceptores en Vuelo
interceptors-in-flight
0
1
11

MONITOR
635
475
792
520
Estaciones Operacionales
stations-operational
0
1
11

MONITOR
499
535
624
580
Total Interceptados
total-intercepted
17
1
11

PLOT
46
406
451
706
Efectividad del Sistema
Tiempo (ticks)
Porcentaje (%)
0.0
1000.0
50.0
100.0
true
false
"" ""
PENS
"Tasa de Intercepción" 1.0 0 -13840069 true "" "plot success-rate"

SWITCH
645
215
837
248
show-detection-ranges?
show-detection-ranges?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a puzzle game where you try to untangle a graph. (A graph is a collection of nodes connected by lines.) Try to reposition the nodes so that no two lines cross. The more nodes, the harder it gets!

## HOW IT WORKS

The game knows how to generate solvable graphs, and it also knows how to detect whether any lines intersect. The details are in the Code tab.

## HOW TO USE IT

Use the STARTING-LEVEL slider to choose the initial difficulty level. If you're a beginner, start at 1. Press SETUP to set up a new board, then press GO to play. Once the GO button is pressed, you can use your mouse to drag the nodes around.

Every level is solvable. One you find a solution, you will automatically be taken to the next level.

## THINGS TO NOTICE

The game only gives you solvable graphs. How might the game be able to guarantee this? (One answer is in the Code tab.)

Can you draw an example of an unsolvable graph on a piece of paper? How many nodes are in the smallest unsolvable graph?

On early levels, you can usually untangle the nodes without too much thought. On later levels, you'll probably need to develop some conscious strategies. What strategies do you find most effective? When your friends play, do they use the same strategies you do? Use the MOVES counter to keep track of how many moves it takes you to untangle the graph.

## THINGS TO TRY

See how high a level you can solve.

Try to solve each level in the fewest number of MOVES.

## EXTENDING THE MODEL

Are there any other ways of generating solvable graphs besides the SETUP-LEVEL? Does it matter what method is used? The more links you can make, the harder the level will be, but if you make too many links, the level might not be solvable at all!

Wherever two links intersect, add a small, brightly colored turtle to mark the intersection. (You'll need two breeds of turtle, one for the nodes, one for the markers. Intersecting Links Example has code for locating the intersection points.)

Make it possible to select multiple nodes and move them together.

## NETLOGO FEATURES

The nodes are turtles; the lines connecting them are links. The code does not make use of patches (other than to make a plain white background).

NetLogo does not have a primitive which detects whether two links intersect. To do the detection, the code uses the `subtract-headings` primitive and some math.

## RELATED MODELS

Intersecting Links Example -- has sample code for finding the point where two links intersect (unlike this model, which only determines whether that point exists or not)

## CREDITS AND REFERENCES

Thanks to Josh Unterman and Seth Tisue for their work on this model and to Jim Lyons for coding advice.

Original version created by John Tantalo, from an original concept by Mary Radcliffe. Tantalo's site is here: http://planarity.net/.

Solvable graphs are called "planar graphs" by mathematicians. See https://en.wikipedia.org/wiki/Planar_graph.

Thanks to Connor Bain for updating this model to work in NetLogo Web in 2021.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2007).  NetLogo Planarity model.  http://ccl.northwestern.edu/netlogo/models/Planarity.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2007 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2007 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
