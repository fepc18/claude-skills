# ATAM Reference Guide

Referencia técnica del método ATAM para uso durante la facilitación.

---

## ¿Qué es ATAM?

ATAM (Architecture Tradeoff Analysis Method) fue creado por Rick Kazman, Mark Klein y Paul Clements en el SEI como evolución del método SAAM. Su objetivo es analizar qué tan bien una arquitectura satisface los atributos de calidad y hacer explícitos los tradeoffs.

## Cuándo usar ATAM

Apropiado cuando:
- Se diseña una arquitectura nueva para un sistema significativo
- Se toma una decisión arquitectónica importante (migración, re-plataforma)
- Se quiere evaluación formal antes de comprometerse con una dirección técnica
- El sistema tiene atributos de calidad conflictivos

No apropiado para:
- Sistemas pequeños o de corta vida
- Decisiones de diseño de bajo nivel
- Auditorías de código o revisiones de implementación

---

## Estructura de un Escenario de Calidad (SEI)

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| Fuente | Origen del estímulo | Usuario final, sistema externo, operador |
| Estímulo | El evento que ocurre | Falla de servidor, pico de tráfico |
| Artefacto | Parte del sistema afectada | Servicio de pagos, base de datos |
| Entorno | Condiciones en que ocurre | Producción, horario pico |
| Respuesta | Cómo debe responder el sistema | Failover automático |
| Medida | Cómo medir la respuesta | < 30 segundos, 0 pérdida de datos |

---

## Los 4 tipos de hallazgos ATAM

| Tipo | Símbolo | Definición |
|------|---------|------------|
| Punto de Sensibilidad | PS | Decisión cuyo cambio afecta directamente un atributo de calidad |
| Tradeoff | TR | Decisión que afecta dos o más atributos en direcciones opuestas |
| Riesgo | R | Decisión (o ausencia) que puede comprometer un atributo |
| No-Riesgo | NR | Decisión analizada que no representa riesgo |

---

## Atributos de calidad comunes

| Atributo | Métricas típicas |
|----------|-----------------|
| Disponibilidad | Uptime %, MTTR, MTBF |
| Rendimiento | Latencia (p50/p95/p99), throughput (req/s) |
| Seguridad | Tiempo de detección, vectores cubiertos |
| Modificabilidad | Tiempo para implementar un cambio tipo |
| Testeabilidad | Cobertura, tiempo de ciclo de prueba |
| Usabilidad | Tasa de error, tiempo en tarea |
| Interoperabilidad | Protocolos soportados, tiempo de integración |
| Escalabilidad | RPS máximo, costo por unidad de carga |

---

## ATAM vs. otros métodos SEI

| Método | Cuándo usar | Duración típica | Rigor |
|--------|-------------|-----------------|-------|
| QAW | Antes de diseñar — elicitar atributos | 1 día | Medio |
| SAAM | Evaluación rápida de arquitectura existente | 1 día | Bajo |
| **ATAM** | Evaluación formal con análisis de tradeoffs | 2-5 días | Alto |
| CBAM | Análisis costo-beneficio de decisiones | Variable | Alto |

---

## Bibliografía

- Bass, L., Clements, P., Kazman, R. *Software Architecture in Practice*, 4th ed. Addison-Wesley, 2021.
- Clements, P., et al. *Evaluating Software Architectures: Methods and Case Studies*. Addison-Wesley, 2002.
- SEI Technical Report CMU/SEI-2000-TR-004 — disponible en sei.cmu.edu
