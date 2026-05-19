/// Caché en memoria del perfil del usuario actual.
///
/// Se carga una sola vez en [AuthWrapper] al iniciar sesión.
/// Todos los widgets lo leen sincrónicamente sin round trips adicionales.
class ProfileCache {
  ProfileCache._();

  static String _role = 'sudo';
  static String? _institutionId;

  static String get role => _role;
  static String? get institutionId => _institutionId;
  static bool get isAdmin => _role == 'admin';
  static bool get isSudo => _role == 'sudo';

  static void set({required String role, String? institutionId}) {
    _role = role;
    _institutionId = institutionId;
  }

  static void clear() {
    _role = 'sudo';
    _institutionId = null;
  }
}
