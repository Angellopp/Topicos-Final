# 🎯 Escenarios de Prueba - Iron Dome

## 📋 Batería Completa de Pruebas

Esta guía proporciona escenarios de prueba estructurados para evaluar diferentes aspectos del sistema Iron Dome bajo condiciones controladas.

---

## 🧪 Categorías de Pruebas

### **1. Pruebas de Funcionalidad Básica**
### **2. Pruebas de Rendimiento**
### **3. Pruebas de Estrés**
### **4. Pruebas de Robustez**
### **5. Pruebas de Optimización**

---

## 🔬 1. Pruebas de Funcionalidad Básica

### **Test 1.1: Funcionamiento Normal**
**Objetivo:** Verificar operación básica del sistema

**Configuración:**
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

**Procedimiento:**
1. Ejecutar `setup`
2. Ejecutar `go` por 500 ticks
3. Observar comportamiento normal

**Resultados Esperados:**
- Tasa de éxito: 85-95%
- Detección automática funcionando
- Interceptores persiguiendo objetivos
- Sin errores de ejecución

**Criterios de Éxito:**
- ✅ Sistema detecta misiles (cambio a naranja)
- ✅ Estaciones lanzan interceptores
- ✅ Intercepción visible con explosiones amarillas
- ✅ Métricas actualizándose correctamente

---

### **Test 1.2: Detección y Rastreo**
**Objetivo:** Verificar sistema de detección radar

**Configuración:**
```
num-defense-stations: 1
detection-range-param: 20
interception-range-param: 15
attack-frequency: 5
missiles-per-attack: 1
```

**Procedimiento:**
1. Lanzar misil único con `emergency-launch-attack`
2. Observar cambio de color del misil
3. Verificar que estación lo rastrea

**Resultados Esperados:**
- Misil cambia de rojo a naranja al entrar en rango
- Estación debe mostrar actividad de rastreo

---

### **Test 1.3: Cálculo Balístico**
**Objetivo:** Verificar precisión de intercepción

**Configuración:**
```
interceptor-speed-param: 3.0
missile-speed: 1.0
attack-frequency: 5
```

**Procedimiento:**
1. Configurar interceptores muy rápidos vs. misiles lentos
2. Observar tasa de intercepción
3. Verificar que interceptores alcanzan objetivos

**Resultados Esperados:**
- Tasa de éxito > 95%
- Interceptores alcanzan misiles antes del impacto

---

## ⚡ 2. Pruebas de Rendimiento

### **Test 2.1: Múltiples Estaciones**
**Objetivo:** Evaluar coordinación entre estaciones

**Configuración:**
```
num-defense-stations: 6
detection-range-param: 15
interception-range-param: 12
attack-frequency: 10
missiles-per-attack: 3
```

**Procedimiento:**
1. Ejecutar simulación por 1000 ticks
2. Observar distribución de carga entre estaciones
3. Medir eficiencia del sistema

**Métricas a Evaluar:**
- Tasa de éxito con múltiples estaciones
- Tiempo de respuesta promedio
- Utilización de cada estación

**Resultados Esperados:**
- Mejora en tasa de éxito vs. test 1.1
- Redundancia operacional visible
- Sin sobrecarga de estaciones individuales

---

### **Test 2.2: Escalabilidad de Amenazas**
**Objetivo:** Evaluar respuesta a incremento gradual de amenazas

**Configuración Base:**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
interceptor-speed-param: 2.5
```

**Procedimiento:**
Ejecutar 5 sub-tests incrementales:

| Sub-Test | missiles-per-attack | attack-frequency | Duración |
|----------|---------------------|------------------|----------|
| 2.2a | 1 | 5 | 200 ticks |
| 2.2b | 2 | 8 | 200 ticks |
| 2.2c | 3 | 10 | 200 ticks |
| 2.2d | 4 | 12 | 200 ticks |
| 2.2e | 5 | 15 | 200 ticks |

**Análisis:**
- Graficar tasa de éxito vs. intensidad de ataque
- Identificar punto de saturación del sistema
- Documentar degradación de rendimiento

---

### **Test 2.3: Optimización de Velocidades**
**Objetivo:** Encontrar balance óptimo interceptor/misil

**Configuración Variables:**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
attack-frequency: 8
missiles-per-attack: 2
```

**Matriz de Pruebas:**

| Test | interceptor-speed | missile-speed | Tasa Esperada |
|------|-------------------|---------------|---------------|
| 2.3a | 2.0 | 1.0 | >90% |
| 2.3b | 2.5 | 1.2 | >85% |
| 2.3c | 3.0 | 1.5 | >80% |
| 2.3d | 2.0 | 1.8 | >60% |
| 2.3e | 1.5 | 2.0 | >40% |

**Análisis:**
- Determinar ratio crítico velocidad interceptor/misil
- Identificar configuración óptima costo-efectiva

---

## 🔥 3. Pruebas de Estrés

### **Test 3.1: Saturación del Sistema**
**Objetivo:** Encontrar límites operacionales del sistema

**Configuración:**
```
num-defense-stations: 3
detection-range-param: 12
interception-range-param: 10
interceptor-speed-param: 2.0
missile-speed: 1.5
attack-frequency: 18
missiles-per-attack: 5
```

**Procedimiento:**
1. Ejecutar por 300 ticks
2. Usar `emergency-launch-attack` cada 50 ticks
3. Observar degradación del sistema

**Métricas Críticas:**
- Tasa de éxito bajo estrés
- Número de amenazas simultáneas máximo
- Tiempo de recuperación del sistema

**Resultados Esperados:**
- Tasa de éxito < 60%
- Múltiples impactos simultáneos
- Sistema saturado pero funcional

---

### **Test 3.2: Ataque Coordinado Masivo**
**Objetivo:** Simular ataque militar coordinado

**Configuración:**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
interceptor-speed-param: 2.5
missile-speed: 1.3
attack-frequency: 20
missiles-per-attack: 4
```

**Procedimiento:**
1. Lanzar 3 `emergency-launch-attack` consecutivos
2. Observar respuesta del sistema
3. Medir tiempo de recuperación

**Escenario:**
- 15 misiles lanzados en ~30 ticks
- Evaluación de priorización bajo presión extrema
- Análisis de efectividad vs. ataques de saturación

---

### **Test 3.3: Misiles de Alta Velocidad**
**Objetivo:** Evaluar respuesta a amenazas supersónicas

**Configuración:**
```
num-defense-stations: 4
detection-range-param: 20
interception-range-param: 15
interceptor-speed-param: 2.5
missile-speed: 2.0
attack-frequency: 8
missiles-per-attack: 2
```

**Procedimiento:**
1. Ejecutar simulación con misiles muy rápidos
2. Observar eficiencia de intercepción
3. Analizar tiempo de respuesta crítico

**Desafíos Esperados:**
- Ventana de intercepción muy reducida
- Necesidad de detección temprana
- Posible falla en intercepción tardía

---

## 🛡️ 4. Pruebas de Robustez

### **Test 4.1: Falla de Estaciones**
**Objetivo:** Evaluar redundancia y recuperación

**Configuración:**
```
num-defense-stations: 5
detection-range-param: 15
interception-range-param: 12
attack-frequency: 10
missiles-per-attack: 3
```

**Procedimiento:**
1. Ejecutar por 200 ticks (operación normal)
2. Usar `disable-random-station` 2 veces
3. Continuar por 200 ticks más
4. Usar `repair-all-stations`
5. Ejecutar 200 ticks finales

**Análisis:**
- Degradación de rendimiento con estaciones dañadas
- Capacidad de compensación del sistema
- Recuperación post-reparación

**Métricas:**
- Tasa de éxito: Normal vs. Degradado vs. Recuperado
- Cobertura territorial afectada
- Tiempo de adaptación del sistema

---

### **Test 4.2: Cobertura Territorial**
**Objetivo:** Evaluar puntos ciegos y sobreposición

**Configuración:**
```
num-defense-stations: 3
detection-range-param: 12
interception-range-param: 10
show-detection-ranges?: On
```

**Procedimiento:**
1. Observar visualmente áreas de cobertura
2. Identificar zonas sin protección
3. Lanzar ataques específicos en puntos ciegos
4. Documentar vulnerabilidades

**Análisis Geográfico:**
- Mapear zonas de cobertura efectiva
- Identificar gaps en la defensa
- Evaluar necesidad de estaciones adicionales

---

### **Test 4.3: Ataques Direccionales**
**Objetivo:** Evaluar vulnerabilidades direccionales

**Configuración:**
```
num-defense-stations: 4
attack-frequency: 15
missiles-per-attack: 3
```

**Procedimiento:**
1. Observar patrones de lanzamiento aleatorio
2. Identificar sectores más vulnerables
3. Analizar efectividad por región

**Nota:** Los misiles se lanzan aleatoriamente, pero se puede observar patrones de efectividad según la geometría del sistema.

---

## 🎯 5. Pruebas de Optimización

### **Test 5.1: Configuración Óptima**
**Objetivo:** Encontrar configuración de máxima efectividad

**Metodología:** Grid Search sistemático

**Variables a Optimizar:**
```
num-defense-stations: [3, 4, 5, 6]
detection-range-param: [12, 15, 18, 20]
interception-range-param: [10, 12, 15]
interceptor-speed-param: [2.0, 2.5, 3.0]
```

**Procedimiento:**
1. Ejecutar cada combinación por 500 ticks
2. Registrar tasa de éxito promedio
3. Analizar trade-offs costo-efectividad
4. Identificar configuración óptima

**Matriz de Resultados:**
Documentar en tabla: Configuración → Tasa de Éxito → Costo Relativo

---

### **Test 5.2: Análisis de Sensibilidad**
**Objetivo:** Identificar parámetros más críticos

**Configuración Base:**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
interceptor-speed-param: 2.5
missile-speed: 1.2
```

**Procedimiento:**
Para cada parámetro, variar ±20% y medir impacto:

| Parámetro | Variación | Impacto Esperado |
|-----------|-----------|------------------|
| `num-defense-stations` | 3→5 | Alto |
| `detection-range-param` | 12→18 | Alto |
| `interceptor-speed-param` | 2.0→3.0 | Muy Alto |
| `interception-range-param` | 10→14 | Medio |
| `reload-time-param` | 6→10 | Bajo |

**Análisis:**
- Ranking de importancia de parámetros
- Identificación de factores críticos
- Recomendaciones de configuración

---

### **Test 5.3: Eficiencia de Recursos**
**Objetivo:** Optimizar relación costo-beneficio

**Escenarios de Presupuesto:**

**Escenario A: Presupuesto Mínimo**
```
num-defense-stations: 3
detection-range-param: 12
interception-range-param: 10
interceptor-speed-param: 2.0
```

**Escenario B: Presupuesto Medio**
```
num-defense-stations: 4
detection-range-param: 15
interception-range-param: 12
interceptor-speed-param: 2.5
```

**Escenario C: Presupuesto Alto**
```
num-defense-stations: 6
detection-range-param: 20
interception-range-param: 15
interceptor-speed-param: 3.0
```

**Análisis ROI:**
- Efectividad por unidad de costo
- Punto de rendimientos decrecientes
- Recomendación de inversión óptima

---

## 📊 Plantilla de Reporte de Pruebas

### **Para cada test, documentar:**

```
TEST ID: [Número de test]
FECHA: [Fecha de ejecución]
DURACIÓN: [Ticks ejecutados]
CONFIGURACIÓN: [Parámetros usados]

RESULTADOS:
- Tasa de Éxito: [%]
- Total Misiles: [cantidad]
- Interceptados: [cantidad]
- Impactos: [cantidad]
- Amenazas Máx Simultáneas: [cantidad]

OBSERVACIONES:
- [Comportamientos notables]
- [Anomalías detectadas]
- [Patrones identificados]

CONCLUSIONES:
- [Cumplimiento de objetivos]
- [Recomendaciones]
- [Próximos pasos]
```

---

## 🎯 Casos de Uso Específicos

### **Caso 1: Evaluación de Compra**
**Escenario:** Decidir cuántas estaciones comprar
**Tests Recomendados:** 2.1, 4.1, 5.1, 5.3
**Objetivo:** Optimizar número de estaciones vs. presupuesto

### **Caso 2: Configuración Operacional**
**Escenario:** Configurar sistema existente
**Tests Recomendados:** 1.1, 2.3, 5.2
**Objetivo:** Maximizar efectividad con hardware fijo

### **Caso 3: Evaluación de Amenazas**
**Escenario:** Prepararse para amenazas específicas
**Tests Recomendados:** 3.1, 3.2, 3.3
**Objetivo:** Validar efectividad contra amenazas conocidas

### **Caso 4: Mantenimiento Preventivo**
**Escenario:** Planificar mantenimiento sin vulnerabilidades
**Tests Recomendados:** 4.1, 4.2
**Objetivo:** Identificar redundancias críticas

---

## 🏆 Benchmarks de Referencia

### **Sistema Iron Dome Real:**
- Tasa de éxito reportada: ~90%
- Cobertura: ~150 km²
- Tiempo de respuesta: <15 segundos
- Costo por interceptor: ~$50,000

### **Objetivos de Simulación:**
- Tasa de éxito objetivo: >85%
- Tiempo de respuesta: <20 ticks
- Eficiencia: >80% interceptores alcanzan objetivo
- Robustez: >70% efectividad con 1 estación dañada

---

## ⚡ Tests de Regresión

### **Ejecutar antes de cambios de código:**

1. **Test Básico:** 1.1 (Funcionamiento Normal)
2. **Test de Estrés:** 3.1 (Saturación)
3. **Test de Robustez:** 4.1 (Falla de Estaciones)

### **Criterios de Aceptación:**
- ✅ Sin errores de ejecución
- ✅ Tasa de éxito dentro de ±5% de línea base
- ✅ Todas las métricas actualizándose
- ✅ Comportamiento visual correcto

---

**¡Estos escenarios proporcionan una evaluación exhaustiva del sistema Iron Dome!** 🛡️🎯

*Documenta todos los resultados para crear una base de conocimiento sólida sobre el rendimiento del sistema.*
