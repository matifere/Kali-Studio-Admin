import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/activity/activity_bloc.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/repositories/alumnos_repository.dart';

part 'alumnos_event.dart';
part 'alumnos_state.dart';

/// Gestiona la carga de alumnos desde Supabase y la paginación del directorio.
///
/// El widget [StudentDirectory] solo dispara eventos y reacciona
/// a estados — sin [FutureBuilder] ni [setState].
class AlumnosBloc extends Bloc<AlumnosEvent, AlumnosState> {
  final ActivityBloc? _activityBloc;
  final AlumnosRepository _repository;

  AlumnosBloc({ActivityBloc? activityBloc, required AlumnosRepository repository})
      : _activityBloc = activityBloc,
        _repository = repository,
        super(AlumnosInitial()) {
    on<AlumnosLoadRequested>(_onLoadRequested);
    on<AlumnosPageChanged>(_onPageChanged);
    on<AlumnosFilterChanged>(_onFilterChanged);
    on<AlumnosStudentStatusChanged>(_onStudentStatusChanged);
  }

  // ── Carga / refresco ───────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    AlumnosLoadRequested event,
    Emitter<AlumnosState> emit,
  ) async {
    final prevState = state;

    // Si ya hay datos cargados, refrescamos en background sin mostrar spinner
    // para que la UI no desaparezca mientras llegan los datos nuevos.
    if (prevState is! AlumnosLoaded) {
      emit(AlumnosLoading());
    }

    try {
      final instId = ProfileCache.institutionId;
      final students = await _repository.getStudents(instId);

      if (prevState is AlumnosLoaded) {
        final prevIds = {for (final s in prevState.students) s.id};
        final newIds = {for (final s in students) s.id};

        // Alumno añadido
        if (students.length > prevState.students.length) {
          final newest = students
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
          _activityBloc?.add(ActivityLogged(ActivityEntry(
            title: 'Alumno registrado',
            subtitle: '${newest.name} fue añadido al directorio.',
            category: ActivityCategory.alumno,
            timestamp: DateTime.now(),
          )));
        }

        // Alumno eliminado
        final removedIds = prevIds.difference(newIds);
        for (final id in removedIds) {
          final removed = prevState.students.firstWhere((s) => s.id == id);
          _activityBloc?.add(ActivityLogged(ActivityEntry(
            title: 'Alumno eliminado',
            subtitle: '${removed.name} fue eliminado del directorio.',
            category: ActivityCategory.alumno,
            timestamp: DateTime.now(),
          )));
        }
      }

      // Preservar filtros activos para que la búsqueda no se resetee al recargar
      emit(AlumnosLoaded(
        students: students,
        searchQuery: prevState is AlumnosLoaded ? prevState.searchQuery : '',
        patologiaFilter:
            prevState is AlumnosLoaded ? prevState.patologiaFilter : null,
        isActiveFilter:
            prevState is AlumnosLoaded ? prevState.isActiveFilter : null,
      ));
    } catch (e) {
      emit(AlumnosError('No se pudieron cargar los alumnos: $e'));
    }
  }

  // ── Cambio de página ───────────────────────────────────────────────────────
  void _onPageChanged(
    AlumnosPageChanged event,
    Emitter<AlumnosState> emit,
  ) {
    final current = state;
    if (current is AlumnosLoaded) {
      emit(current.copyWithPage(event.page));
    }
  }

  // ── Cambio de estado activo/inactivo (patch local, sin refetch) ───────────
  void _onStudentStatusChanged(
    AlumnosStudentStatusChanged event,
    Emitter<AlumnosState> emit,
  ) {
    final current = state;
    if (current is! AlumnosLoaded) return;

    final updated = [
      for (final s in current.students)
        s.id == event.studentId ? s.copyWith(isActive: event.isActive) : s,
    ];

    // Re-aplica los filtros activos; si el alumno sale de la lista filtrada
    // la página actual puede quedar fuera de rango, por eso se clampa.
    var next = AlumnosLoaded(
      students: updated,
      currentPage: current.currentPage,
      searchQuery: current.searchQuery,
      patologiaFilter: current.patologiaFilter,
      isActiveFilter: current.isActiveFilter,
    );
    if (next.currentPage > next.totalPages) {
      next = next.copyWithPage(next.totalPages);
    }
    emit(next);
  }

  // ── Cambio de filtros ──────────────────────────────────────────────────────
  void _onFilterChanged(
    AlumnosFilterChanged event,
    Emitter<AlumnosState> emit,
  ) {
    final current = state;
    if (current is AlumnosLoaded) {
      emit(AlumnosLoaded(
        students: current.students,
        currentPage: 1,
        searchQuery: event.searchQuery,
        patologiaFilter: event.patologiaFilter,
        isActiveFilter: event.isActiveFilter,
      ));
    }
  }
}
