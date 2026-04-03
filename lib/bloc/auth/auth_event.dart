part of 'auth_bloc.dart';

abstract class AuthEvent {}

/// El usuario presionó "Entrar" en el LoginScreen.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

/// El usuario presionó "Crear Cuenta" en el RegisterScreen.
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });
}

/// El usuario cerraró sesión.
class AuthLogoutRequested extends AuthEvent {}

/// Reinicia el BLoC a [AuthInitial]. Se dispara después de navegar
/// con éxito, para que rebuilds / hot reloads no re-disparen el listener.
class AuthReset extends AuthEvent {}
