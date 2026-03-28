import 'package:supabase_flutter/supabase_flutter.dart';

class SupaAuthClass {
  final GoTrueClient auth = Supabase.instance.client.auth;

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
