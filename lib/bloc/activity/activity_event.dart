part of 'activity_bloc.dart';

abstract class ActivityEvent {}

/// Registra una nueva entrada de actividad.
class ActivityLogged extends ActivityEvent {
  final ActivityEntry entry;
  ActivityLogged(this.entry);
}

/// Limpia todo el historial de actividad de la sesión.
class ActivityCleared extends ActivityEvent {}
