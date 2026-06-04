/// Caché en memoria del perfil del usuario actual.
///
/// Se carga una sola vez en [AuthWrapper] al iniciar sesión.
/// Todos los widgets lo leen sincrónicamente sin round trips adicionales.
class ProfileCache {
  ProfileCache._();

  static String _role = 'client';
  static String? _institutionId;
  static String? _fullName;
  static bool _loaded = false;

  static String get role => _role;
  static String? get institutionId => _institutionId;
  static String? get fullName => _fullName;
  static bool get isAdmin => _role == 'admin';
  static bool get isSudo => _role == 'sudo';
  /// true si el caché fue poblado al menos una vez (sesión activa previa).
  static bool get isLoaded => _loaded;

  static void set({required String role, String? institutionId, String? fullName}) {
    _role = role;
    _institutionId = institutionId;
    _fullName = fullName;
    _loaded = true;
  }

  static void clear() {
    _role = 'client';
    _institutionId = null;
    _fullName = null;
    _loaded = false;
  }
}
