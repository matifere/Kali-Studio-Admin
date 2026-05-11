import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupaAuthClass {
  final GoTrueClient auth = Supabase.instance.client.auth;

  Future<String> registrarAlumno(
      String email, String password, String fullName) async {
    try {
      // Obtenemos el institution_id del admin actual
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) return 'Error: Sin sesión de administrador';
      
      final adminProfile = await Supabase.instance.client
          .from('profiles')
          .select('institution_id')
          .eq('id', adminId)
          .maybeSingle();
          
      final instId = adminProfile?['institution_id'];

      // Creamos un cliente temporal sin persistencia para no sobreescribir la sesión del admin
      final tempClient = SupabaseClient(
        dotenv.env['URL']!,
        dotenv.env['ANON']!,
        authOptions: AuthClientOptions(
          pkceAsyncStorage: _DummyAsyncStorage(),
          autoRefreshToken: false,
        ),
      );

      final AuthResponse respuesta = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': 'client', 'institution_id': instId},
      );

      if (respuesta.user != null) {
        try {
          // Usamos el cliente temporal (el alumno) para actualizar SU PROPIO perfil,
          // esto es permitido por la política RLS (id = auth.uid())
          await tempClient.from('profiles').update({
            'full_name': fullName,
            'role': 'client',
            'institution_id': instId,
          }).eq('id', respuesta.user!.id);
        } catch (e) {
          // Error profile
          print('Error actualizando el perfil del alumno: $e');
        }
        await tempClient.auth.signOut();
        tempClient.dispose();
        return 'Ok';
      } else {
        await tempClient.auth.signOut();
        tempClient.dispose();
        return 'Error session == null';
      }
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
        data: {'full_name': fullName, 'role': 'admin'},
      );
      if (respuesta.user != null) {
        try {
          await Supabase.instance.client.from('profiles').update({
            'full_name': fullName,
            'role': 'admin',
          }).eq('id', respuesta.user!.id);
        } catch (e) {
          //print('Error actualizando el perfil: $e');
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
              .select('role')
              .eq('id', respuesta.user!.id)
              .maybeSingle();

          if (profile != null && profile['role'] == 'client') {
            await auth.signOut();
            return 'Acceso denegado: No tienes permisos de administrador.';
          }
        } catch (e) {
          //print('Error obteniendo el rol: $e');
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

class _DummyAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};
  @override Future<String?> getItem({required String key}) async => _map[key];
  @override Future<void> removeItem({required String key}) async => _map.remove(key);
  @override Future<void> setItem({required String key, required String value}) async { _map[key] = value; }
}
