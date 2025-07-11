# 🎛️ Guía de Configuración de Interfaz - Iron Dome

## 📋 Configuración Completa de la Interfaz NetLogo

### **1. Sliders (Variables Configurables)**

#### **Configuración de Defensa**
```
Slider: num-defense-stations
- Variable: num-defense-stations
- Min: 2
- Max: 8
- Default: 4
- Increment: 1
- Units: estaciones

Slider: detection-range-param
- Variable: detection-range-param
- Min: 10
- Max: 25
- Default: 15
- Increment: 1
- Units: unidades

Slider: interception-range-param
- Variable: interception-range-param
- Min: 8
- Max: 20
- Default: 12
- Increment: 1
- Units: unidades

Slider: reload-time-param
- Variable: reload-time-param
- Min: 5
- Max: 15
- Default: 8
- Increment: 1
- Units: ticks
```

#### **Configuración de Rendimiento**
```
Slider: interceptor-speed-param
- Variable: interceptor-speed-param
- Min: 1.5
- Max: 3.0
- Default: 2.5
- Increment: 0.1
- Units: unidades/tick

Slider: missile-speed
- Variable: missile-speed
- Min: 0.8
- Max: 2.0
- Default: 1.2
- Increment: 0.1
- Units: unidades/tick
```

#### **Configuración de Amenazas**
```
Slider: attack-frequency
- Variable: attack-frequency
- Min: 1
- Max: 20
- Default: 8
- Increment: 1
- Units: %

Slider: missiles-per-attack
- Variable: missiles-per-attack
- Min: 1
- Max: 5
- Default: 2
- Increment: 1
- Units: misiles

Slider: num-targets
- Variable: num-targets
- Min: 3
- Max: 10
- Default: 6
- Increment: 1
- Units: objetivos
```

### **2. Switches**

```
Switch: show-detection-ranges?
- Variable: show-detection-ranges?
- Default: On (true)
- Descripción: "Mostrar rangos de detección"
```

### **3. Botones de Control**

#### **Botones Principales**
```
Button: Setup
- Display Name: "SETUP"
- Commands: setup
- Forever: No
- Action Type: Observer
- Key: S

Button: Go
- Display Name: "GO/STOP"
- Commands: go
- Forever: Yes
- Action Type: Observer
- Key: G
```

#### **Botones de Prueba**
```
Button: Emergency Attack
- Display Name: "ATAQUE MASIVO"
- Commands: emergency-launch-attack
- Forever: No
- Action Type: Observer

Button: Disable Station
- Display Name: "DAÑAR ESTACIÓN"
- Commands: disable-random-station
- Forever: No
- Action Type: Observer

Button: Repair Stations
- Display Name: "REPARAR TODO"
- Commands: repair-all-stations
- Forever: No
- Action Type: Observer
```

### **4. Monitores de Estado**

#### **Métricas Primarias**
```
Monitor: Success Rate
- Display Name: "Tasa de Éxito (%)"
- Reporter: success-rate
- Decimal Places: 1

Monitor: Active Threats
- Display Name: "Amenazas Activas"
- Reporter: active-threats
- Decimal Places: 0

Monitor: Interceptors in Flight
- Display Name: "Interceptores en Vuelo"
- Reporter: interceptors-in-flight
- Decimal Places: 0

Monitor: Operational Stations
- Display Name: "Estaciones Operacionales"
- Reporter: stations-operational
- Decimal Places: 0
```

#### **Métricas Secundarias**
```
Monitor: Threat Level
- Display Name: "Nivel de Amenaza"
- Reporter: threat-level
- Decimal Places: 0

Monitor: Total Incoming
- Display Name: "Total Misiles Lanzados"
- Reporter: total-incoming-missiles
- Decimal Places: 0

Monitor: Total Intercepted
- Display Name: "Total Interceptados"
- Reporter: total-intercepted
- Decimal Places: 0

Monitor: Total Missed
- Display Name: "Total Impactos"
- Reporter: total-missed
- Decimal Places: 0

Monitor: Average Ammo
- Display Name: "Munición Promedio"
- Reporter: average-station-ammo
- Decimal Places: 0

Monitor: Zone Protection
- Display Name: "Protección de Zona (%)"
- Reporter: zone-protection-analysis
- Decimal Places: 1
```

### **5. Plots (Gráficos)**

#### **Plot 1: Efectividad del Sistema**
```
Plot Name: "Efectividad del Sistema"
- X-axis label: "Tiempo (ticks)"
- Y-axis label: "Porcentaje (%)"
- X min: 0
- X max: 1000
- Y min: 0
- Y max: 100

Pen: "Tasa de Intercepción"
- Name: "success-rate"
- Color: Green
- Mode: Line
- Commands: plot success-rate
```

#### **Plot 2: Actividad de Amenazas**
```
Plot Name: "Actividad de Amenazas"
- X-axis label: "Tiempo (ticks)"
- Y-axis label: "Cantidad"
- X min: 0
- X max: 1000
- Y min: 0
- Y max: 20

Pen 1: "Misiles Activos"
- Name: "threats"
- Color: Red
- Mode: Line
- Commands: plot active-threats

Pen 2: "Interceptores"
- Name: "interceptors"
- Color: Green
- Mode: Line
- Commands: plot interceptors-in-flight
```

### **6. Outputs (Opcionales)**

```
Output Box: Sistema de Logs
- Font Size: 11
- Width: 300
- Height: 100
- Commands para usar:
  output-print "Mensaje del sistema"
  output-print (word "Intercepción exitosa en tick " ticks)
```

## 🎨 Layout Recomendado de la Interfaz

### **Distribución Visual:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                          WORLD VIEW                                │
│                      (Área de Simulación)                          │
│                         800 x 600                                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐
│   CONTROLES     │ │   PARÁMETROS    │ │         MÉTRICAS            │
│                 │ │                 │ │                             │
│ [SETUP]         │ │ defense-stations│ │ Tasa Éxito: [95.2%]        │
│ [GO/STOP]       │ │ detection-range │ │ Amenazas: [3]               │
│ [ATAQUE MASIVO] │ │ intercept-range │ │ Interceptores: [5]          │
│ [DAÑAR ESTACIÓN]│ │ reload-time     │ │ Estaciones: [4/4]           │
│ [REPARAR TODO]  │ │ interceptor-speed│ │ Nivel: [MEDIO]             │
│                 │ │ missile-speed   │ │ Total Lanzados: [87]        │
│ □ show-ranges   │ │ attack-frequency│ │ Interceptados: [83]         │
│                 │ │ missiles/attack │ │ Impactos: [4]               │
│                 │ │ num-targets     │ │ Munición: [100%]            │
│                 │ │                 │ │ Protección: [96.5%]         │
└─────────────────┘ └─────────────────┘ └─────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        GRÁFICOS                                    │
│ ┌─────────────────────────┐ ┌─────────────────────────────────────┐│
│ │   Efectividad Sistema   │ │      Actividad Amenazas             ││
│ │                         │ │                                     ││
│ │ 100% ┌─────────────────┐│ │  20 ┌─────────────────────────────┐││
│ │      │      ████████   ││ │     │  ▲                         ││
│ │  50% │   ███████████   ││ │  10 │ ▲ ▲  ▲                    ││
│ │      │███████████████  ││ │     │▲   ▲  ▲ ▲                 ││
│ │   0% └─────────────────┘│ │   0 └─────────────────────────────┘││
│ │      0    500   1000    │ │      0    500   1000             ││
│ └─────────────────────────┘ └─────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

## 🔧 Instrucciones Paso a Paso

### **Paso 1: Crear Nuevo Modelo**
1. Abrir NetLogo
2. File → New
3. Copiar y pegar el código completo
4. File → Save As → "Iron_Dome_Simulation.nlogo"

### **Paso 2: Configurar Sliders**
1. Click derecho en área gris → "Slider"
2. Para cada slider:
   - Global variable: [nombre del slider]
   - Minimum: [valor mínimo]
   - Maximum: [valor máximo]
   - Increment: [incremento]
   - Value: [valor por defecto]
   - Units (opcional): [unidades]

### **Paso 3: Configurar Switches**
1. Click derecho en área gris → "Switch"
2. Global variable: show-detection-ranges?
3. Position: On (para activar por defecto)

### **Paso 4: Configurar Botones**
1. Click derecho en área gris → "Button"
2. Para cada botón:
   - Commands: [comando a ejecutar]
   - Display name: [texto visible]
   - Forever: [Yes para go, No para otros]
   - Action key: [tecla de acceso rápido]

### **Paso 5: Configurar Monitores**
1. Click derecho en área gris → "Monitor"
2. Para cada monitor:
   - Reporter: [función a reportar]
   - Display name: [título del monitor]
   - Decimal places: [decimales a mostrar]

### **Paso 6: Configurar Plots**
1. Click derecho en área gris → "Plot"
2. En "Edit Plot":
   - Name: [nombre del gráfico]
   - X axis label: [etiqueta eje X]
   - Y axis label: [etiqueta eje Y]
   - X min/max, Y min/max: [rangos]
3. Para cada Pen:
   - Name: [nombre de la línea]
   - Color: [color de la línea]
   - Mode: Line
   - Update commands: plot [variable]

## 🎮 Configuraciones Preestablecidas

### **Configuración 1: Escenario Normal**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
reload-time-param: 8
interceptor-speed-param: 2.5
missile-speed: 1.2
attack-frequency: 8
missiles-per-attack: 2
num-targets: 6
show-detection-ranges?: On
```

### **Configuración 2: Máxima Defensa**
```
num-defense-stations: 6
detection-range-param: 22
interception-range-param: 18
reload-time-param: 5
interceptor-speed-param: 3.0
missile-speed: 1.0
attack-frequency: 8
missiles-per-attack: 2
num-targets: 6
show-detection-ranges?: On
```

### **Configuración 3: Alto Estrés**
```
num-defense-stations: 3
detection-range-param: 12
interception-range-param: 10
reload-time-param: 10
interceptor-speed-param: 2.0
missile-speed: 1.8
attack-frequency: 15
missiles-per-attack: 4
num-targets: 8
show-detection-ranges?: On
```

## 📱 Teclas de Acceso Rápido

```
S - Setup (Inicializar)
G - Go/Stop (Ejecutar/Pausar)
Espacio - Pausa temporal
R - Reset view
+ - Zoom in
- - Zoom out
```

## 🎯 Indicadores Visuales en la Simulación

### **Colores y Formas:**
- 🏠 **Estaciones (Azul Brillante)**: Casas azules operacionales
- 🏠 **Estaciones Dañadas (Gris)**: Casas grises no funcionales
- ✈️ **Misiles No Detectados (Rojo)**: Aviones rojos
- ✈️ **Misiles Detectados (Naranja)**: Aviones naranjas
- 🎯 **Objetivos (Blanco)**: Círculos blancos
- 🎯 **Objetivos Impactados (Rojo)**: Círculos rojos
- ➡️ **Interceptores (Verde)**: Flechas verdes
- ⭐ **Intercepción Exitosa (Amarillo)**: Estrellas amarillas
- 🔴 **Impacto Destructivo (Rojo)**: Círculos rojos grandes

### **Zonas del Mapa:**
- 🟢 **Zona Verde (Arriba)**: Territorio defendido
- 🟤 **Zona Marrón (Abajo)**: Territorio hostil
- 🔴 **Línea Roja (Centro)**: Frontera

## ⚠️ Troubleshooting de Interfaz

### **Problema: Sliders no funcionan**
- Verificar que el nombre del slider coincida exactamente con la variable
- Verificar que el rango mínimo sea menor que el máximo
- Reiniciar NetLogo si es necesario

### **Problema: Monitores muestran error**
- Verificar que la función reporter existe
- Verificar sintaxis del nombre de la función
- Asegurar que la función devuelve un valor numérico

### **Problema: Botones no responden**
- Verificar que el comando existe
- Verificar sintaxis del comando
- Para botón Go, asegurar que Forever esté en "Yes"

### **Problema: Plots no se actualizan**
- Verificar comando "plot [variable]" en cada pen
- Verificar que las variables existen
- Ajustar rangos X e Y si es necesario

---

**¡La simulación Iron Dome está lista para usar!** 🚀🛡️

*Recuerda ajustar los parámetros según el escenario que quieras simular y observar cómo cambia la efectividad del sistema de defensa.*
