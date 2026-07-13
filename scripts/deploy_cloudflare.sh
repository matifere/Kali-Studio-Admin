#!/bin/bash
# Script para compilar Flutter en Cloudflare Pages

# 1. Clonar el repositorio de Flutter (versión estable)
git clone https://github.com/flutter/flutter.git -b stable

# 2. Agregar Flutter al PATH temporalmente para la compilación
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Habilitar soporte web
flutter config --enable-web

# 4. Crear archivo .env temporal para que la compilación de assets no falle
# Se tomarán las variables de entorno configuradas en Cloudflare Pages
cat <<EOF > .env
URL='${URL}'
ANON='${ANON}'
VAPID_PUBLIC_KEY='${VAPID_PUBLIC_KEY}'
EOF

# 5. Compilar la aplicación para producción
# --pwa-strategy=none: NO generar el service worker de Flutter. Evita que los
# usuarios queden con una versión vieja cacheada; la caché la controlan los
# headers HTTP de web/_headers (no-cache en los archivos de entrada).
flutter build web --release --pwa-strategy=none

# 6. Reemplazar el flutter_service_worker.js (queda vacío con --pwa-strategy=none)
# por uno AUTODESTRUCTIVO. Los usuarios que todavía tienen el SW viejo instalado
# van a buscar este archivo (mismo nombre/URL), y este:
#   - se activa de inmediato (skipWaiting), sin quedar "en espera"
#   - borra todas las caches viejas
#   - se desregistra a sí mismo
#   - recarga las pestañas abiertas
# Resultado: se actualizan con UNA sola recarga automática, sin cerrar/reabrir
# ni borrar caché a mano. Corre una única vez por usuario y después desaparece.
cat > build/web/flutter_service_worker.js <<'SW'
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (event) {
  event.waitUntil((async function () {
    // 1) Borrar las caches viejas de Flutter.
    try {
      var keys = await caches.keys();
      await Promise.all(keys.map(function (k) { return caches.delete(k); }));
    } catch (e) {}
    // 2) Tomar control de las pestañas abiertas. Sin esto, match() no las
    //    devuelve y navigate() no tiene permiso para recargarlas.
    try { await self.clients.claim(); } catch (e) {}
    // 3) Recargar todas las ventanas (incluí las no controladas todavía).
    try {
      var wins = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
      wins.forEach(function (c) { try { c.navigate(c.url); } catch (e) {} });
    } catch (e) {}
    // 4) Desregistrarse: en la próxima carga ya no hay SW.
    try { await self.registration.unregister(); } catch (e) {}
  })());
});
SW
