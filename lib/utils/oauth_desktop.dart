import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> handleDesktopOAuth(String clientId, String redirectUri) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  
  final Uri url = Uri.https(
    'auth.mercadopago.com',
    '/authorization',
    {
      'client_id': clientId,
      'response_type': 'code',
      'platform_id': 'mp',
      'redirect_uri': redirectUri,
      'state': 'port:$port',
    },
  );

  await launchUrl(url, mode: LaunchMode.externalApplication);

  await for (HttpRequest request in server) {
    if (request.uri.path == '/token') {
      final refreshToken = request.uri.queryParameters['refresh_token'];
      
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write("<html><body style='font-family:sans-serif;text-align:center;padding:50px;background:#f3f4f6;color:#1f2937;'><h2>Autenticación exitosa.</h2><p>Ya podés volver a Argity.</p><script>setTimeout(() => window.close(), 1500);</script></body></html>");
      await request.response.close();
      await server.close();
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await Supabase.instance.client.auth.setSession(refreshToken);
      }
      break;
    } else {
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('''
          <html>
            <body style='font-family:sans-serif;text-align:center;padding:50px;'>
              <h2>Procesando tu sesión...</h2>
              <script>
                const hash = window.location.hash.substring(1);
                const params = new URLSearchParams(hash);
                const refreshToken = params.get('refresh_token');
                if (refreshToken) {
                  window.location.href = "/token?refresh_token=" + refreshToken;
                } else {
                  document.body.innerHTML = "<h2>Error: No se encontró el token</h2>";
                }
              </script>
            </body>
          </html>
        ''');
      await request.response.close();
    }
  }
}
