part of 'rutinas_bloc.dart';

abstract class RutinasState {}

class RutinasInitial extends RutinasState {}

class RutinasLoading extends RutinasState {}

class RutinasError extends RutinasState {
  final String message;
  RutinasError(this.message);
}

class RutinasLoaded extends RutinasState {
  final List<RoutineStudent> students;
  final List<Routine> routines;

  /// Asignación vigente por id de alumno; ausencia = sin rutina.
  final Map<String, RoutineAssignment> assignments;
  final String searchQuery;

  RutinasLoaded({
    required this.students,
    required this.routines,
    required this.assignments,
    this.searchQuery = '',
  });

  List<RoutineStudent> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    final q = searchQuery.toLowerCase();
    return students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  RutinasLoaded copyWith({
    List<RoutineStudent>? students,
    List<Routine>? routines,
    Map<String, RoutineAssignment>? assignments,
    String? searchQuery,
  }) {
    return RutinasLoaded(
      students: students ?? this.students,
      routines: routines ?? this.routines,
      assignments: assignments ?? this.assignments,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
