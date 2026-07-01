# Original User Request

## Initial Request — 2026-07-01T14:25:55Z

# Teamwork Project Prompt

Generar un reporte detallado para implementar un sistema de temas personalizable por el usuario en una aplicación Flutter. El reporte debe identificar exhaustivamente todos los colores "hardcodeados" actuales y proponer una arquitectura de tematización utilizando Bloc (Cubits). No se debe proponer ni realizar ninguna modificación a la base de datos por el momento. **IMPORTANTE: Ningún archivo de código fuente debe ser modificado por los agentes.**

Working directory: /mnt/hdd2t/prog/Kali-Studio-Admin
Integrity mode: development

## Requirements

### R1. Búsqueda exhaustiva de colores
Realizar un análisis exhaustivo del directorio `lib/` para encontrar todas las instancias de colores hardcodeados (ej. `Colors.red`, `Color(0xFF...)`, `Colors.blue[200]`, etc.).

### R2. Arquitectura de Tematización (Cubit)
Diseñar y proponer una arquitectura para manejar el estado del tema utilizando el patrón Bloc, específicamente empleando Cubits. Se debe mostrar cómo integrar el Cubit con el `ThemeData` nativo de Flutter.

### R3. Generación de Reporte sin modificaciones de código
El entregable final debe ser un archivo Markdown llamado `reporte_temas.md` en la raiz del proyecto con el reporte. Los agentes tienen **estrictamente prohibido** realizar modificaciones en el código fuente del proyecto (`lib/`, etc.). 

## Acceptance Criteria

### Verificación del Reporte
- [ ] Se generó un archivo llamado `reporte_temas.md` en el directorio del proyecto.
- [ ] El reporte contiene una lista exhaustiva de todos los archivos y líneas de código en `lib/` que contienen colores hardcodeados.
- [ ] El reporte incluye un diseño conceptual claro y ejemplos de código para implementar el cambio de tema usando un Cubit.
- [ ] El reporte no incluye código SQL ni modificaciones de base de datos.
- [ ] **Ningún** archivo de código fuente del proyecto fue modificado por el equipo de agentes (verificable comprobando que no haya cambios en git o archivos modificados en `lib/`).
