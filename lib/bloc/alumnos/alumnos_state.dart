part of 'alumnos_bloc.dart';

abstract class AlumnosState {}

/// Estado inicial antes de solicitar la carga.
class AlumnosInitial extends AlumnosState {}

/// Cargando datos desde la base de datos.
class AlumnosLoading extends AlumnosState {}

/// Datos cargados y listos para mostrar.
class AlumnosLoaded extends AlumnosState {
  final List<Student> students;
  final int currentPage;
  static const int perPage = 4;

  AlumnosLoaded({required this.students, this.currentPage = 1});

  int get totalPages =>
      (students.length / perPage).ceil().clamp(1, 999);

  List<Student> get pageStudents {
    if (students.isEmpty) return [];
    final start = (currentPage - 1) * perPage;
    final end = (start + perPage).clamp(0, students.length);
    return students.sublist(start, end);
  }

  /// Crea una copia con la página actualizada (sin recargar datos).
  AlumnosLoaded copyWithPage(int page) =>
      AlumnosLoaded(students: students, currentPage: page);
}

/// Error al cargar los datos.
class AlumnosError extends AlumnosState {
  final String message;

  AlumnosError(this.message);
}
