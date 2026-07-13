// Cloudflare Pages Functions — middleware global.
//
// Reset ÚNICO por navegador para sacar a los usuarios de una versión vieja
// cacheada (la que tenía el login roto). En la respuesta del documento HTML,
// y solo si el navegador todavía no fue reseteado, manda:
//
//   Clear-Site-Data: "storage"
//
// que borra: CacheStorage (donde el SW guardaba la app vieja), IndexedDB/
// localStorage (la sesión) y los service workers registrados. Acto seguido
// setea una cookie para NO repetirlo (así no quedan en un loop de deslogueo).
// Los usuarios se deslogean una sola vez y vuelven a entrar contra el build
// nuevo, que ya loguea bien.
//
// OJO: NO se incluye "cache". Ese directivo limpia el HTTP cache del que
// depende la navegación en curso y puede dejar la primera carga EN BLANCO
// (bug conocido de Chrome). Además es redundante: los archivos de entrada ya
// salen con no-cache (web/_headers), así que el HTTP cache ya se revalida solo.
//
// Nota: a los usuarios que todavía tienen el SW viejo de Flutter este header no
// los alcanza (el SW sirve la navegación desde su propia caché, sin pegarle a
// la red); a esos los cura el flutter_service_worker.js autodestructivo. Entre
// los dos mecanismos se cubren todos los casos.
//
// Para volver a forzar un reset en el futuro, cambiá el valor de RESET_ID.

const RESET_ID = '20260712';
const COOKIE = 'kali_reset';

export async function onRequest(context) {
  const { request, next } = context;
  const response = await next();

  try {
    // ¿Ya fue reseteado este navegador?
    const cookies = request.headers.get('Cookie') || '';
    if (cookies.includes(COOKIE + '=' + RESET_ID)) return response;

    // Actuar solo sobre el documento HTML (la navegación), no sobre cada asset.
    const ct = response.headers.get('Content-Type') || '';
    if (!ct.includes('text/html')) return response;

    const out = new Response(response.body, response);
    out.headers.set('Clear-Site-Data', '"storage"');
    out.headers.append(
      'Set-Cookie',
      COOKIE + '=' + RESET_ID + '; Path=/; Max-Age=31536000; Secure; SameSite=Lax; HttpOnly',
    );
    return out;
  } catch (e) {
    // Ante cualquier error, no romper el sitio: devolver la respuesta original.
    return response;
  }
}
