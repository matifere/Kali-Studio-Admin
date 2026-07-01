# Original User Request

## Initial Request — 2026-07-01T14:40:08-03:00

Analyze and modify the database queries in Kali-Studio-Admin to include the "sudo" user (app owner) in the list of trainers, specifically in the trainers section and when creating/filtering shifts (turnos).

Working directory: /mnt/hdd2t/prog/Kali-Studio-Admin
Integrity mode: benchmark

## Requirements

### R1. Modificar consultas de entrenadores
Modificar la obtención de datos de la base de datos para que las listas de entrenadores en la aplicación también incluyan a los usuarios que tengan el rol `sudo`.

### R2. Integración en turnos
Asegurarse de que el usuario `sudo` aparezca como una opción válida al momento de crear, asignar y filtrar turnos (shifts).

### R3. Preservar privilegios de administrador
La lógica existente que le otorga permisos elevados al usuario `sudo` en toda la aplicación debe permanecer intacta. Lo que los agentes implementen no debe romper ni modificar el nivel de acceso superior del `sudo`.

## Acceptance Criteria

### Verificación de obtención de datos
- [ ] Las consultas a la base de datos devuelven usuarios con el rol `sudo` junto a los entrenadores regulares.

### Verificación en Interfaz (Turnos y Entrenadores)
- [ ] El menú o lista desplegable para crear un turno muestra al usuario `sudo` como un entrenador seleccionable.
- [ ] El panel de "Entrenadores" (si aplica) muestra al usuario `sudo`.

### Verificación de Regresión
- [ ] El usuario `sudo` conserva todos sus accesos de administrador sin restricciones accidentales.
