import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Gestiona toda la lógica de autenticación (login, registro, logout).
///
/// Las pantallas disparan [AuthEvent]s y reaccionan a [AuthState]s
/// usando [BlocConsumer] — sin ningún [setState].
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupaAuthClass _authService;

  AuthBloc({SupaAuthClass? authService})
      : _authService = authService ?? SupaAuthClass(),
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthReset>((event, emit) => emit(AuthInitial()));
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authService.logInUsuario(event.email, event.password);
    if (result == 'Ok') {
      emit(AuthSuccess());
    } else {
      emit(AuthFailure(result));
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────────
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authService.registrarUsuario(
      event.email,
      event.password,
      event.fullName,
    );
    if (result == 'Ok') {
      emit(AuthSuccess());
    } else {
      emit(AuthFailure(result));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authService.logOut();
    if (result == 'Ok') {
      emit(AuthSuccess());
    } else {
      emit(AuthFailure(result));
    }
  }
}
