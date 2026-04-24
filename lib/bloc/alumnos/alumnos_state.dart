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
  final List<String> availablePlans;
  final int currentPage;

  // Filtros activos
  final String searchQuery;
  final String? planFilter;
  final bool? isActiveFilter;

  static const int perPage = 4;

  AlumnosLoaded._({
    required this.students,
    required this.filteredStudents,
    required this.availablePlans,
    required this.currentPage,
    required this.searchQuery,
    this.planFilter,
    this.isActiveFilter,
  });

  /// Factory constructor que precalcula los alumnos filtrados y los planes disponibles en O(n).
  factory AlumnosLoaded({
    required List<Student> students,
    int currentPage = 1,
    String searchQuery = '',
    String? planFilter,
    bool? isActiveFilter,
  }) {
    final queryLower = searchQuery.toLowerCase().trim();
    final List<Student> filtered = [];
    final Set<String> plansSet = {};

    // Calculamos filtros y planes en una sola pasada (O(n))
    for (final s in students) {
      if (s.plan.isNotEmpty) {
        plansSet.add(s.plan);
      }
      
      bool matches = true;
      if (queryLower.isNotEmpty) {
        matches = s.name.toLowerCase().contains(queryLower) || 
                  s.email.toLowerCase().contains(queryLower);
      }
      if (matches && planFilter != null && planFilter.isNotEmpty) {
        matches = s.plan == planFilter;
      }
      if (matches && isActiveFilter != null) {
        matches = s.isActive == isActiveFilter;
      }
      
      if (matches) {
        filtered.add(s);
      }
    }

    final plansList = plansSet.toList()..sort();

    return AlumnosLoaded._(
      students: students,
      filteredStudents: filtered,
      availablePlans: plansList,
      currentPage: currentPage,
      searchQuery: searchQuery,
      planFilter: planFilter,
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
        availablePlans: availablePlans,
        currentPage: page,
        searchQuery: searchQuery,
        planFilter: planFilter,
        isActiveFilter: isActiveFilter,
      );
}

/// Error al cargar los datos.
class AlumnosError extends AlumnosState {
  final String message;

  AlumnosError(this.message);
}
