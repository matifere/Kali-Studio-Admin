import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/activity/activity_bloc.dart';
import 'package:kali_studio/models/student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'alumnos_event.dart';
part 'alumnos_state.dart';

/// Gestiona la carga de alumnos desde Supabase y la paginación del directorio.
///
/// El widget [StudentDirectory] solo dispara eventos y reacciona
/// a estados — sin [FutureBuilder] ni [setState].
class AlumnosBloc extends Bloc<AlumnosEvent, AlumnosState> {
  final ActivityBloc? _activityBloc;

  AlumnosBloc({ActivityBloc? activityBloc})
      : _activityBloc = activityBloc,
        super(AlumnosInitial()) {
    on<AlumnosLoadRequested>(_onLoadRequested);
    on<AlumnosPageChanged>(_onPageChanged);
    on<AlumnosFilterChanged>(_onFilterChanged);
  }

  // ── Carga inicial ──────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    AlumnosLoadRequested event,
    Emitter<AlumnosState> emit,
  ) async {
    emit(AlumnosLoading());
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('''
            *, 
            subscriptions!subscriptions_user_id_fkey(*, plans(*)), 
            reservations!reservations_user_id_fkey(*, class_sessions(*))
          ''')
          .eq('role', 'client');

      final students =
          response.map<Student>((data) => Student.fromJson(data)).toList();

      // Loggear si se añadió un alumno nuevo (previamente ya había datos)
      final prevState = state;
      if (prevState is AlumnosLoaded && students.length > prevState.students.length) {
        final newest = students.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
        _activityBloc?.add(ActivityLogged(ActivityEntry(
          title: 'Alumno registrado',
          subtitle: '${newest.name} fue añadido al directorio.',
          category: ActivityCategory.alumno,
          timestamp: DateTime.now(),
        )));
      }

      emit(AlumnosLoaded(students: students));
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

  // ── Cambio de filtros ──────────────────────────────────────────────────────
  void _onFilterChanged(
    AlumnosFilterChanged event,
    Emitter<AlumnosState> emit,
  ) {
    final current = state;
    if (current is AlumnosLoaded) {
      // Re-invoca el factory para computar los nuevos filtros y resetea a página 1
      emit(AlumnosLoaded(
        students: current.students,
        currentPage: 1,
        searchQuery: event.searchQuery,
        planFilter: event.planFilter,
        isActiveFilter: event.isActiveFilter,
      ));
    }
  }
}

