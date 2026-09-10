import 'package:flutter/foundation.dart';

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
  static bool _isActive = false;
  static bool _isProfileDisabled = false;

  static bool _hasCustomThemes = false;
  static bool _hasCustomLogo = false;
  static bool _hasNotifications = false;
  static int? _maxStudents;
  static int? _maxCoaches;

  static final ValueNotifier<String?> institutionNameNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> institutionLogoNotifier = ValueNotifier(null);

  static String get role => _role;
  static String? get institutionId => _institutionId;
  static String? get fullName => _fullName;
  static bool get isAdmin => _role == 'admin';
  static bool get isSudo => _role == 'sudo';
  static bool get hasCustomThemes => _hasCustomThemes;
  static bool get hasCustomLogo => _hasCustomLogo;
  static bool get hasNotifications => _hasNotifications;
  static int? get maxStudents => _maxStudents;
  static int? get maxCoaches => _maxCoaches;

  /// true si el caché fue poblado al menos una vez (sesión activa previa).
  static bool get isLoaded => _loaded;

  /// Combinación del estado de la institución/suscripción y la cuenta.
  /// Si esto es false, el usuario no debe acceder a la app (InactiveScreen).
  static bool get isActive => _isActive && !_isProfileDisabled;
  static bool get isProfileDisabled => _isProfileDisabled;

  static void set({
    required String role,
    String? institutionId,
    String? fullName,
  }) {
    _role = role;
    _institutionId = institutionId;
    _fullName = fullName;
    _loaded = true;
  }

  static void updateIsActive(bool value) {
    _isActive = value;
  }

  static void updateIsProfileDisabled(bool value) {
    _isProfileDisabled = value;
  }
  
  static void updateHasCustomThemes(bool value) {
    _hasCustomThemes = value;
  }
  
  static void updateHasCustomLogo(bool value) {
    _hasCustomLogo = value;
  }

  static void updateHasNotifications(bool value) {
    _hasNotifications = value;
  }

  static void updateMaxStudents(int? value) {
    _maxStudents = value;
  }

  static void updateMaxCoaches(int? value) {
    _maxCoaches = value;
  }

  static void clear() {
    _role = 'client';
    _institutionId = null;
    _fullName = null;
    _loaded = false;
    _isActive = false;
    _isProfileDisabled = false;
    _hasCustomThemes = false;
    _hasCustomLogo = false;
    _hasNotifications = false;
    _maxStudents = null;
    _maxCoaches = null;
    institutionNameNotifier.value = null;
    institutionLogoNotifier.value = null;
  }
}
