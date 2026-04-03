part of 'auth_bloc.dart';

abstract class AuthState {}

/// Estado inicial antes de cualquier acción de autenticación.
class AuthInitial extends AuthState {}

/// Petición en curso (muestra el spinner en el botón).
class AuthLoading extends AuthState {}

/// Autenticación exitosa.
class AuthSuccess extends AuthState {}

/// Error de autenticación, con el mensaje a mostrar.
class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}
