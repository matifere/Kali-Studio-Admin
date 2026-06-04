import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupaAuthClass {
  final GoTrueClient auth = Supabase.instance.client.auth;

  // URL y key se configuran desde main.dart justo después de Supabase.initialize().
  static String _supabaseUrl = '';
  static String _supabaseAnon = '';

  static void configure({required String url, required String anonKey}) {
    _supabaseUrl = url;
    _supabaseAnon = anonKey;
  }

  // Registra un nuevo usuario via REST API directamente para no interferir
  // con la sesión del admin (el tempClient compartía SharedPreferences con el
  // cliente principal y lo deslogueaba al hacer signOut).
  Future<String> _signUpViaHttp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final supabaseUrl = _supabaseUrl;
    final supabaseAnon = _supabaseAnon;

    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnon,
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': metadata,
      }),
    );

    if (response.body.isEmpty) {
      return 'Error:Respuesta vacía del servidor. Verificá la conexión.';
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      return 'Error:${body['message'] ?? body['msg'] ?? 'Error al registrar usuario'}';
    }

    // Sin confirmación por email: `{ "user": { "id": "..." }, ... }`
    // Con confirmación por email: `{ "id": "...", "email": "..." }`
    final userId = (body['user']?['id'] ?? body['id']) as String?;
    if (userId == null) return 'Error:No se recibió ID del nuevo usuario';
    return userId;
  }

  Future<String> registrarAlumno(
      String email, String password, String fullName) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) return 'Error: Sin sesión de administrador';

      final adminProfile = await Supabase.instance.client
          .from('profiles')
          .select('institution_id')
          .eq('id', adminId)
          .maybeSingle();

      final instId = adminProfile?['institution_id'] as String?;
      if (instId == null) {
        return 'Error: No se pudo obtener la institución del administrador';
      }

      final result = await _signUpViaHttp(
        email: email,
        password: password,
        metadata: {
          'full_name': fullName,
          'role': 'client',
          'institution_id': instId
        },
      );

      if (result.startsWith('Error:')) return result.substring(6);

      final newUserId = result;

      // El trigger ya creó el perfil; este upsert asegura que todos los campos estén correctos.
      await Supabase.instance.client.from('profiles').upsert({
        'id': newUserId,
        'full_name': fullName,
        'email': email,
        'role': 'client',
        'institution_id': instId,
        'is_active': true,
      });

      return 'Ok';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String> registrarEntrenador(
      String email, String password, String fullName) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) return 'Error: Sin sesión de administrador';

      final adminProfile = await Supabase.instance.client
          .from('profiles')
          .select('institution_id')
          .eq('id', adminId)
          .maybeSingle();

      final instId = adminProfile?['institution_id'] as String?;
      if (instId == null) {
        return 'Error: No se pudo obtener la institución del administrador';
      }

      final result = await _signUpViaHttp(
        email: email,
        password: password,
        metadata: {
          'full_name': fullName,
          'role': 'admin',
          'institution_id': instId
        },
      );

      if (result.startsWith('Error:')) return result.substring(6);

      final newUserId = result;

      await Supabase.instance.client.from('profiles').upsert({
        'id': newUserId,
        'full_name': fullName,
        'email': email,
        'role': 'admin',
        'institution_id': instId,
        'is_active': true,
      });

      return 'Ok:$newUserId';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String> registrarUsuario(
      String email, String password, String fullName) async {
    try {
      // Step 1 — crear usuario vía HTTP para NO abrir sesión local.
      // Si usáramos auth.signUp() dispararía signedIn → el listener de main.dart
      // destruiría el RegisterScreen antes de mostrar feedback.
      final signupResp = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseAnon,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {'full_name': fullName, 'role': 'sudo'},
        }),
      );

      if (signupResp.body.isEmpty) return 'Error de conexión con el servidor.';

      final signupBody = jsonDecode(signupResp.body) as Map<String, dynamic>;

      if (signupResp.statusCode != 200 && signupResp.statusCode != 201) {
        return signupBody['message'] ?? signupBody['msg'] ?? 'Error al registrar usuario';
      }

      // Supabase devuelve { "user": { "id": ... } } sin confirmación de email,
      // o { "id": ..., "email": ... } con confirmación habilitada.
      final userId = (signupBody['user']?['id'] ?? signupBody['id']) as String?;
      if (userId == null) return 'No se recibió ID del nuevo usuario';

      // Step 2 — crear perfil via HTTP usando el token del nuevo usuario.
      // Sin confirmación de email Supabase incluye access_token en la respuesta;
      // con confirmación habilitada no hay token y usamos la anon key (el trigger
      // de Supabase debe crear el perfil en ese caso).
      final accessToken = signupBody['access_token'] as String?;
      final authHeader =
          accessToken != null ? 'Bearer $accessToken' : 'Bearer $_supabaseAnon';

      await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/profiles'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseAnon,
          'Authorization': authHeader,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'id': userId,
          'email': email,
          'full_name': fullName,
          'role': 'sudo',
          'is_active': false,
        }),
      );

      return 'Pending';
    } catch (e) {
      return '$e';
    }
  }

  Future<String> logInUsuario(String email, String password) async {
    try {
      final AuthResponse respuesta = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (respuesta.session != null && respuesta.user != null) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role, is_active')
              .eq('id', respuesta.user!.id)
              .maybeSingle();

          if (profile == null) {
            await auth.signOut();
            return 'Acceso denegado: No se encontró el perfil de usuario.';
          }
          if (profile['role'] == 'client') {
            await auth.signOut();
            return 'Acceso denegado: No tienes permisos de administrador.';
          }
          // Nota: is_active: false no se bloquea aquí porque usuarios sudo con
          // cuenta nueva (pendiente de activación) necesitan llegar a InactiveScreen
          // para completar el pago. AuthWrapper gestiona esa navegación.
        } catch (_) {
          // Si la verificación de permisos falla, denegar acceso por defecto
          // (fail-closed: nunca otorgar acceso ante una falla de seguridad).
          await auth.signOut();
          return 'Error al verificar permisos. Intentá nuevamente.';
        }
        return 'Ok';
      } else {
        return 'Error session == null';
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String> logOut() async {
    try {
      await auth.signOut();
      return 'Ok';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }
}
