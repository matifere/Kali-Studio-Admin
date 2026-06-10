part of 'alumnos_bloc.dart';

abstract class AlumnosEvent {}

/// Solicita la carga inicial de alumnos desde la DB.
class AlumnosLoadRequested extends AlumnosEvent {}

/// El usuario cambió de página en la paginación.
class AlumnosPageChanged extends AlumnosEvent {
  final int page;

  AlumnosPageChanged(this.page);
}

/// Cambió el estado activo/inactivo de un alumno (actualización optimista:
/// patchea la lista en memoria sin refetch; el revert usa el mismo evento).
class AlumnosStudentStatusChanged extends AlumnosEvent {
  final String studentId;
  final bool isActive;

  AlumnosStudentStatusChanged(this.studentId, this.isActive);
}

/// Se aplicaron nuevos filtros en el directorio de alumnos.
class AlumnosFilterChanged extends AlumnosEvent {
  final String searchQuery;
  final String? patologiaFilter;
  final bool? isActiveFilter;

  AlumnosFilterChanged({
    required this.searchQuery,
    this.patologiaFilter,
    this.isActiveFilter,
  });
}
