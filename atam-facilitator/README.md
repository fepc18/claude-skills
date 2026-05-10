# ATAM Workshop

Plugin para facilitar talleres de evaluación de arquitectura usando el método **ATAM** (Architecture Tradeoff Analysis Method) del SEI (Software Engineering Institute, Carnegie Mellon University).

## ¿Qué hace?

Convierte a Claude en un co-facilitador que guía paso a paso por las 5 etapas del método ATAM:

1. **Preparación** — contexto del sistema, drivers del negocio, stakeholders
2. **Árbol de Utilidad** — jerarquía de atributos de calidad con escenarios priorizados
3. **Enfoques Arquitectónicos** — decisiones clave documentadas con sus consecuencias
4. **Análisis** — puntos de sensibilidad, tradeoffs, riesgos y no-riesgos
5. **Reporte Final** — documento ATAM completo en markdown

## Cómo usarlo

Describe lo que quieres evaluar y el skill se activa automáticamente:

- *"Quiero evaluar la arquitectura de nuestro sistema de pagos"*
- *"Hagamos un ATAM del microservicio de inventario"*
- *"Identifica los tradeoffs de esta arquitectura"*
- *"Hay riesgos en este diseño que no hemos visto?"*

## Artefactos generados

- Árbol de utilidad con escenarios priorizados (H/M/B)
- Tabla de enfoques arquitectónicos
- Análisis: PS (puntos de sensibilidad), TR (tradeoffs), R (riesgos), NR (no-riesgos)
- Reporte final ATAM en markdown listo para compartir

## Referencia

Basado en Bass, Clements, Kazman — *Software Architecture in Practice*, 4th ed. (2021) y SEI Technical Report CMU/SEI-2000-TR-004.

---
*Creado por Felipe Pabón — felipepabon.github.io/felipepabon*
