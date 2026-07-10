import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/models/routine.dart';
import 'package:argrity/repositories/rutinas_repository.dart';
import 'package:argrity/services/profile_cache.dart';

part 'rutinas_event.dart';
part 'rutinas_state.dart';

/// Gestiona la sección Rutinas: listado de alumnos, catálogo de rutinas
/// de la institución y la asignación vigente de cada alumno.
class RutinasBloc extends Bloc<RutinasEvent, RutinasState> {
  final RutinasRepository _repository;

  RutinasBloc({required RutinasRepository repository})
      : _repository = repository,
        super(RutinasInitial()) {
    on<RutinasLoadRequested>(_onLoadRequested);
    on<RutinasSearchChanged>(_onSearchChanged);
    on<RutinaCreated>(_onRutinaCreated);
    on<RutinaDeleted>(_onRutinaDeleted);
    on<RutinaAssigned>(_onRutinaAssigned);
    on<RutinaUnassigned>(_onRutinaUnassigned);
  }

  Future<void> _onLoadRequested(
    RutinasLoadRequested event,
    Emitter<RutinasState> emit,
  ) async {
    final prevState = state;

    // Refresco en background si ya hay datos, igual que AlumnosBloc.
    if (prevState is! RutinasLoaded) {
      emit(RutinasLoading());
    }

    try {
      final instId = ProfileCache.institutionId;
      final results = await Future.wait([
        _repository.getStudents(instId),
        _repository.getRoutines(instId),
        _repository.getAssignments(),
      ]);

      emit(RutinasLoaded(
        students: results[0] as List<RoutineStudent>,
        routines: results[1] as List<Routine>,
        assignments: results[2] as Map<String, RoutineAssignment>,
        searchQuery: prevState is RutinasLoaded ? prevState.searchQuery : '',
      ));
    } catch (e) {
      emit(RutinasError('No se pudieron cargar las rutinas: $e'));
    }
  }

  void _onSearchChanged(
    RutinasSearchChanged event,
    Emitter<RutinasState> emit,
  ) {
    final current = state;
    if (current is RutinasLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onRutinaCreated(
    RutinaCreated event,
    Emitter<RutinasState> emit,
  ) async {
    final current = state;
    if (current is! RutinasLoaded) return;

    final instId = ProfileCache.institutionId;
    if (instId == null) {
      emit(RutinasError('No se encontró la institución del usuario.'));
      return;
    }

    try {
      final routine = await _repository.createRoutine(
        institutionId: instId,
        name: event.name,
        description: event.description,
        exercises: event.exercises,
      );
      final routines = [...current.routines, routine]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(current.copyWith(routines: routines));
    } catch (e) {
      emit(RutinasError('No se pudo crear la rutina: $e'));
      emit(current);
    }
  }

  Future<void> _onRutinaDeleted(
    RutinaDeleted event,
    Emitter<RutinasState> emit,
  ) async {
    final current = state;
    if (current is! RutinasLoaded) return;

    try {
      await _repository.deleteRoutine(event.routineId);
      final assignments = {
        for (final entry in current.assignments.entries)
          if (entry.value.routine.id != event.routineId)
            entry.key: entry.value,
      };
      emit(current.copyWith(
        routines: current.routines
            .where((r) => r.id != event.routineId)
            .toList(),
        assignments: assignments,
      ));
    } catch (e) {
      emit(RutinasError('No se pudo eliminar la rutina: $e'));
      emit(current);
    }
  }

  Future<void> _onRutinaAssigned(
    RutinaAssigned event,
    Emitter<RutinasState> emit,
  ) async {
    final current = state;
    if (current is! RutinasLoaded) return;

    try {
      await _repository.assignRoutine(
        userId: event.userId,
        routineId: event.routineId,
      );
      // Patch local sin refetch: reflejar la asignación al instante.
      final routine =
          current.routines.firstWhere((r) => r.id == event.routineId);
      emit(current.copyWith(assignments: {
        ...current.assignments,
        event.userId: RoutineAssignment(
          id: current.assignments[event.userId]?.id ?? '',
          userId: event.userId,
          routine: routine,
          assignedAt: DateTime.now(),
        ),
      }));
    } catch (e) {
      emit(RutinasError('No se pudo asignar la rutina: $e'));
      emit(current);
    }
  }

  Future<void> _onRutinaUnassigned(
    RutinaUnassigned event,
    Emitter<RutinasState> emit,
  ) async {
    final current = state;
    if (current is! RutinasLoaded) return;

    try {
      await _repository.unassignRoutine(event.userId);
      final assignments = {...current.assignments}..remove(event.userId);
      emit(current.copyWith(assignments: assignments));
    } catch (e) {
      emit(RutinasError('No se pudo quitar la rutina: $e'));
      emit(current);
    }
  }
}
