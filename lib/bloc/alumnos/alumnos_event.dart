part of 'alumnos_bloc.dart';

abstract class AlumnosEvent {}

/// Solicita la carga inicial de alumnos desde la DB.
class AlumnosLoadRequested extends AlumnosEvent {}

/// El usuario cambió de página en la paginación.
class AlumnosPageChanged extends AlumnosEvent {
  final int page;

  AlumnosPageChanged(this.page);
}

/// Se aplicaron nuevos filtros en el directorio de alumnos.
class AlumnosFilterChanged extends AlumnosEvent {
  final String searchQuery;
  final String? planFilter;
  final bool? isActiveFilter;

  AlumnosFilterChanged({
    required this.searchQuery,
    this.planFilter,
    this.isActiveFilter,
  });
}
