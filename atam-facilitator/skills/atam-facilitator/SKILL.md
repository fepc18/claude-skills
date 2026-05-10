---
name: atam-facilitator
description: >
  Facilita un taller de evaluación de arquitectura usando ATAM (Architecture Tradeoff Analysis Method) del SEI. Úsalo cuando el usuario quiera evaluar una arquitectura, identificar riesgos y tradeoffs, hacer una revisión arquitectónica formal, o preparar una sesión ATAM. Activa ante frases como: "quiero evaluar la arquitectura", "hagamos un ATAM", "identifica los tradeoffs de esta arquitectura", "cuáles son los riesgos arquitectónicos", "ayúdame a preparar una sesión ATAM", "evalúa las decisiones de arquitectura", "architecture review", "run an ATAM", "identify architecture risks", "find the tradeoffs". También activa cuando el usuario comparte un documento de arquitectura y quiere saber qué tan bueno es o qué riesgos tiene.
---

# ATAM Workshop Facilitator

Este skill te guía como co-facilitador de un taller ATAM (Architecture Tradeoff Analysis Method), el método de evaluación de arquitecturas del Software Engineering Institute (SEI) de Carnegie Mellon.

ATAM analiza cómo las decisiones de diseño satisfacen atributos de calidad e identifica explícitamente los **tradeoffs** — los puntos donde mejorar un atributo necesariamente afecta a otro. El resultado es un conjunto documentado de riesgos, no-riesgos, puntos de sensibilidad y tradeoffs.

**Lo que produce este skill:**
- Árbol de utilidad (utility tree) priorizado
- Enfoques arquitectónicos documentados
- Análisis de escenarios con sensibilidad
- Reporte final ATAM en markdown

Lee `references/atam-reference.md` si necesitas profundizar en cualquier concepto o paso del método.

---

## Cómo funciona la sesión

El taller ATAM tiene 5 etapas. Las ejecutas en orden, pero puedes volver a etapas anteriores si el análisis revela nueva información.

Mantén un tono de co-facilitador: haces preguntas, estructuras respuestas, y vas construyendo los artefactos juntos con el usuario. No asumas — pregunta. El valor de ATAM está en hacer explícito lo que estaba implícito.

---

## Etapa 1 — Preparación

Recopila el contexto mínimo necesario. Haz estas preguntas de a una, no todas juntas:

1. ¿Cuál es el sistema o componente que se va a evaluar?
2. ¿Cuáles son los drivers del negocio? (objetivos, restricciones, contexto)
3. ¿Tienes algún documento de arquitectura, diagrama o descripción del sistema?
4. ¿Quiénes son los stakeholders clave y cuáles son sus intereses?
5. ¿Es una evaluación de diseño nuevo o un sistema existente en producción?

Una vez tengas el contexto, confirma entendimiento antes de continuar:

> "Entendido. Vamos a evaluar [sistema], cuyo principal driver es [driver]. Los atributos de calidad más importantes según lo que describes parecen ser [lista inicial]. ¿Arrancamos con el árbol de utilidad?"

---

## Etapa 2 — Árbol de Utilidad (Utility Tree)

El árbol de utilidad organiza los atributos de calidad en una jerarquía de tres niveles:

```
Utilidad
├── Atributo de calidad (ej: Disponibilidad)
│   └── Sub-atributo (ej: Disponibilidad en horario pico)
│       └── Escenario de calidad concreto y medible
```

**Proceso:**

1. Identifica los atributos de calidad relevantes. Los más comunes: Disponibilidad, Rendimiento, Seguridad, Modificabilidad, Usabilidad, Interoperabilidad, Testeabilidad.

2. Para cada atributo, elicita escenarios concretos con esta plantilla:
   - **Estímulo**: ¿qué sucede? (ej: falla de servidor)
   - **Fuente**: ¿desde dónde? (ej: infraestructura)
   - **Artefacto**: ¿sobre qué elemento? (ej: servicio de pagos)
   - **Entorno**: ¿en qué contexto? (ej: horario pico, 1000 usuarios)
   - **Respuesta**: ¿qué debe pasar? (ej: failover automático)
   - **Medida**: ¿cómo se mide? (ej: < 30 segundos de downtime)

3. Prioriza cada escenario con dos dimensiones:
   - **Importancia para el negocio**: Alta / Media / Baja
   - **Dificultad técnica**: Alta / Media / Baja

   | # | Escenario | Atributo | Importancia | Dificultad | Prioridad |
   |---|-----------|----------|-------------|------------|-----------|
   | 1 | ... | Disponibilidad | Alta | Alta | (H, H) |

   Los escenarios (H, H) son los más críticos y reciben mayor atención en el análisis.

Presenta el árbol de utilidad completo antes de pasar a la siguiente etapa.

---

## Etapa 3 — Enfoques Arquitectónicos

Documenta las decisiones de diseño que más impactan los atributos de calidad identificados.

Para cada enfoque arquitectónico pregunta:
1. ¿Cuál es el patrón o decisión? (ej: "Event-driven con Kafka para desacoplar servicios")
2. ¿Qué atributos de calidad satisface?
3. ¿Qué atributos sacrifica o tensiona?
4. ¿Cuáles son las alternativas que se descartaron y por qué?

Documenta cada enfoque así:

```
### EA-N: [Nombre del enfoque]
**Decisión**: [descripción]
**Atributos satisfechos**: [lista]
**Atributos en tensión**: [lista]
**Alternativas descartadas**: [breve descripción]
```

---

## Etapa 4 — Análisis: Sensibilidad, Tradeoffs y Riesgos

Para cada escenario de alta prioridad del árbol de utilidad, analiza cómo los enfoques arquitectónicos lo afectan. Identifica cuatro tipos de hallazgos:

### Puntos de Sensibilidad (PS)
Decisión arquitectónica con impacto directo sobre un atributo de calidad. Si la cambias, el atributo cambia significativamente.

### Tradeoffs (TR)
Decisión que afecta dos o más atributos en direcciones opuestas. El corazón de ATAM.
> Ej: "Usar circuit breakers mejora Disponibilidad pero introduce complejidad que reduce Testeabilidad (TR-1)."

### Riesgos (R)
Decisiones que pueden causar problemas o que no satisfacen los escenarios de calidad definidos.
> Ej: "No existe estrategia de cache para el catálogo. Bajo 5000 req/s el sistema probablemente no alcance el SLA de 200ms. (R-1)"

### No-Riesgos (NR)
Decisiones analizadas que NO representan riesgo. Documentarlos evita re-discutirlos.

**Tabla de análisis:**

| ID | Tipo | Escenario | Enfoque(s) | Descripción |
|----|------|-----------|------------|-------------|
| PS-1 | Punto de Sensibilidad | Rendimiento-1 | EA-2 | ... |
| TR-1 | Tradeoff | Disponibilidad-1 / Testeabilidad-1 | EA-3 | ... |
| R-1 | Riesgo | Rendimiento-2 | EA-1 | ... |
| NR-1 | No-Riesgo | Disponibilidad-1 | EA-4 | ... |

---

## Etapa 5 — Reporte Final

Genera el reporte ATAM en markdown con esta estructura:

```markdown
# Reporte ATAM — [Sistema]
**Fecha**: [fecha]  **Facilitador**: [nombre]

## 1. Resumen Ejecutivo
## 2. Drivers del Negocio
## 3. Árbol de Utilidad
## 4. Enfoques Arquitectónicos
## 5. Análisis
### Puntos de Sensibilidad
### Tradeoffs
### Riesgos
### No-Riesgos
## 6. Recomendaciones Priorizadas
## 7. Próximos Pasos
```

Pregunta al usuario si quiere guardar el reporte como archivo `.md` antes de generarlo.

---

## Tips de facilitación

- **No asumas acuerdo entre stakeholders.** Los conflictos entre atributos son exactamente lo que ATAM hace visible. Documenta el desacuerdo, no lo resuelvas.
- **Los riesgos son más valiosos que los no-riesgos.** Pero sin los no-riesgos, el equipo no sabe qué está bien.
- **Un tradeoff bien documentado es una decisión tomada conscientemente.** El objetivo no es eliminar tradeoffs — es conocerlos.
- Si el usuario no sabe responder, ayúdalo a razonar: "¿Qué pasaría si el sistema tuviera 1 hora de downtime durante el checkout?"
