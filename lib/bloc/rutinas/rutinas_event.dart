part of 'rutinas_bloc.dart';

abstract class RutinasEvent {}

/// Carga (o refresca) alumnos, catálogo de rutinas y asignaciones.
class RutinasLoadRequested extends RutinasEvent {}

/// Cambia el texto de búsqueda del listado de alumnos.
class RutinasSearchChanged extends RutinasEvent {
  final String query;
  RutinasSearchChanged(this.query);
}

/// Crea una rutina nueva en el catálogo de la institución.
class RutinaCreated extends RutinasEvent {
  final String name;
  final String? description;
  final List<String> exercises;
  RutinaCreated({
    required this.name,
    this.description,
    this.exercises = const [],
  });
}

/// Elimina una rutina del catálogo (y sus asignaciones, por cascade).
class RutinaDeleted extends RutinasEvent {
  final String routineId;
  RutinaDeleted(this.routineId);
}

/// Asigna (o reemplaza) la rutina de un alumno.
class RutinaAssigned extends RutinasEvent {
  final String userId;
  final String routineId;
  RutinaAssigned({required this.userId, required this.routineId});
}

/// Quita la rutina asignada a un alumno.
class RutinaUnassigned extends RutinasEvent {
  final String userId;
  RutinaUnassigned(this.userId);
}
