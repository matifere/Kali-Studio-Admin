import 'package:supabase_flutter/supabase_flutter.dart';

class SupaAuthClass {
  final GoTrueClient auth = Supabase.instance.client.auth;
  Future<String> registrarUsuario(String email, String password) async {
    try {
      final AuthResponse respuesta = await auth.signUp(
        email: email,
        password: password,
      );
      if (respuesta.session != null) {
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
      if (respuesta.session != null) {
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
