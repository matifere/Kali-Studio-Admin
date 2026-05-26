import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupaAuthClass {
  final GoTrueClient auth = Supabase.instance.client.auth;

  // Registra un nuevo usuario via REST API directamente para no interferir
  // con la sesión del admin (el tempClient compartía SharedPreferences con el
  // cliente principal y lo deslogueaba al hacer signOut).
  Future<String> _signUpViaHttp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final supabaseUrl = kIsWeb
        ? 'https://tmfcnvtjzmtpqhzvfxos.supabase.co'
        : dotenv.env['URL']!;
    final supabaseAnon = kIsWeb
        ? 'sb_publishable_TkebjBTlimQS7Uu4HWE-tQ_v3ylhC_b'
        : dotenv.env['ANON']!;
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
      if (instId == null) return 'Error: No se pudo obtener la institución del administrador';

      final result = await _signUpViaHttp(
        email: email,
        password: password,
        metadata: {'full_name': fullName, 'role': 'client', 'institution_id': instId},
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
      if (instId == null) return 'Error: No se pudo obtener la institución del administrador';

      final result = await _signUpViaHttp(
        email: email,
        password: password,
        metadata: {'full_name': fullName, 'role': 'admin', 'institution_id': instId},
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
      final AuthResponse respuesta = await auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': 'sudo'},
      );
      if (respuesta.user != null) {
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': respuesta.user!.id,
            'email': email,
            'full_name': fullName,
            'role': 'sudo',
            'is_active': false,
          });
        } catch (e) {
          print('Error upserting profile: $e');
        }
        await auth.signOut();
        return 'Pending';
      } else {
        return 'Error session == null';
      }
    } on AuthException catch (e) {
      return e.message;
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

          if (profile != null && profile['role'] == 'client') {
            await auth.signOut();
            return 'Acceso denegado: No tienes permisos de administrador.';
          }
        } catch (_) {}
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
