part of 'alumnos_bloc.dart';

abstract class AlumnosState {}

/// Estado inicial antes de solicitar la carga.
class AlumnosInitial extends AlumnosState {}

/// Cargando datos desde la base de datos.
class AlumnosLoading extends AlumnosState {}

/// Datos cargados y listos para mostrar.
class AlumnosLoaded extends AlumnosState {
  final List<Student> students;
  final List<Student> filteredStudents;
  final List<String> availablePatologias;
  final int currentPage;

  // Filtros activos
  final String searchQuery;
  final String? patologiaFilter;
  final bool? isActiveFilter;

  static const int perPage = 4;

  AlumnosLoaded._({
    required this.students,
    required this.filteredStudents,
    required this.availablePatologias,
    required this.currentPage,
    required this.searchQuery,
    this.patologiaFilter,
    this.isActiveFilter,
  });

  /// Factory que precalcula los alumnos filtrados y las patologías disponibles en O(n).
  factory AlumnosLoaded({
    required List<Student> students,
    int currentPage = 1,
    String searchQuery = '',
    String? patologiaFilter,
    bool? isActiveFilter,
  }) {
    final queryLower = searchQuery.toLowerCase().trim();
    final patologiaLower = patologiaFilter?.toLowerCase().trim();
    final List<Student> filtered = [];
    final Set<String> patologiasSet = {};

    for (final s in students) {
      for (final p in s.patologias) {
        if (p.isNotEmpty) patologiasSet.add(p);
      }

      bool matches = true;
      if (queryLower.isNotEmpty) {
        matches = s.name.toLowerCase().contains(queryLower) ||
            s.email.toLowerCase().contains(queryLower);
      }
      if (matches && patologiaLower != null && patologiaLower.isNotEmpty) {
        matches = s.patologias.any((p) => p.toLowerCase() == patologiaLower);
      }
      if (matches && isActiveFilter != null) {
        matches = s.isActive == isActiveFilter;
      }

      if (matches) filtered.add(s);
    }

    final patologiasList = patologiasSet.toList()..sort();

    return AlumnosLoaded._(
      students: students,
      filteredStudents: filtered,
      availablePatologias: patologiasList,
      currentPage: currentPage,
      searchQuery: searchQuery,
      patologiaFilter: patologiaFilter,
      isActiveFilter: isActiveFilter,
    );
  }

  int get totalPages =>
      (filteredStudents.length / perPage).ceil().clamp(1, 999);

  List<Student> get pageStudents {
    if (filteredStudents.isEmpty) return [];
    final start = (currentPage - 1) * perPage;
    final end = (start + perPage).clamp(0, filteredStudents.length);
    return filteredStudents.sublist(start, end);
  }

  /// Crea una copia con la página actualizada (sin recargar datos ni recomputar filtros).
  AlumnosLoaded copyWithPage(int page) => AlumnosLoaded._(
        students: students,
        filteredStudents: filteredStudents,
        availablePatologias: availablePatologias,
        currentPage: page,
        searchQuery: searchQuery,
        patologiaFilter: patologiaFilter,
        isActiveFilter: isActiveFilter,
      );
}

/// Error al cargar los datos.
class AlumnosError extends AlumnosState {
  final String message;

  AlumnosError(this.message);
}
