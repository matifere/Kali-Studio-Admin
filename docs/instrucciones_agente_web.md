# Instrucciones para el Agente Web (Cloudflare Pages)

## Contexto
Se ha implementado un sistema de actualizaciones automáticas bloqueantes para la aplicación de escritorio (Windows y macOS) construida en Flutter. La aplicación consulta un archivo estático alojado en Cloudflare Pages para saber si existe una nueva versión y desde dónde descargarla.

## Tareas a realizar en la página web

### 1. Crear el archivo de Control de Versiones (`version.json`)
Debes crear un archivo llamado **exactamente** `version.json` y ubicarlo en la **raíz pública** del proyecto web (la carpeta que se despliega en Cloudflare Pages, usualmente `public/`, `dist/`, o `build/` dependiendo del framework que estés usando).

El contenido de este archivo debe tener el siguiente formato JSON estricto:

```json
{
  "latest_version": "1.0.1",
  "windows_url": "https://TU_DOMINIO.com/downloads/Argity-Windows.exe",
  "mac_url": "https://TU_DOMINIO.com/downloads/Argity-Mac.dmg",
  "release_notes": "Mejoras generales en la pantalla de reservas y corrección de errores menores."
}
```

**Reglas importantes para este archivo:**
*   `latest_version`: Debe coincidir con la nomenclatura semántica (ej. `1.0.1`). La app de Flutter usará este string para compararlo con su versión actual.
*   `windows_url` y `mac_url`: Deben ser links directos a los instaladores.
*   `release_notes`: Un string de texto que se le mostrará al usuario en la pantalla de actualización obligatoria.

### 2. Configurar la carpeta de Descargas (Opcional pero recomendado)
Si los instaladores se van a alojar en el mismo Cloudflare Pages, crea una carpeta llamada `downloads/` en el directorio público y asegúrate de que los archivos `.exe` y `.dmg` se coloquen allí antes de cada despliegue.

*(Nota: Los archivos `.exe` o `.dmg` pueden llegar a ser grandes. Si Cloudflare Pages tiene límites estrictos de tamaño por archivo para tu plan, los instaladores podrían alojarse en GitHub Releases o AWS S3, y en el `version.json` simplemente colocarías esas URLs externas).*

### 3. Configuración de CORS (Si aplica)
Asegúrate de que Cloudflare Pages permita peticiones `GET` desde la aplicación de escritorio. Por defecto, los archivos estáticos en Cloudflare Pages no tienen restricciones estrictas de CORS que impidan a una app Flutter leerlos, pero tenlo en cuenta si agregas headers de seguridad restrictivos (`_headers`).

## Flujo de trabajo para futuras actualizaciones
Cada vez que se compile una nueva versión de la app de escritorio:
1. Subir los nuevos instaladores a la URL correspondiente.
2. Actualizar el número de `latest_version` en `version.json`.
3. Actualizar el texto en `release_notes`.
4. Hacer el *deploy* a Cloudflare Pages.
