part of 'alumnos_bloc.dart';

abstract class AlumnosEvent {}

/// Solicita la carga inicial de alumnos desde la DB.
class AlumnosLoadRequested extends AlumnosEvent {}

/// El usuario cambió de página en la paginación.
class AlumnosPageChanged extends AlumnosEvent {
  final int page;

  AlumnosPageChanged(this.page);
}
