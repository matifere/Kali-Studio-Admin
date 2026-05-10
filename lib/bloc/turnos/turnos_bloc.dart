import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/activity/activity_bloc.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/models/schedule_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

part 'turnos_event.dart';
part 'turnos_state.dart';

class TurnosBloc extends Bloc<TurnosEvent, TurnosState> {
  final ActivityBloc? _activityBloc;

  TurnosBloc({ActivityBloc? activityBloc})
      : _activityBloc = activityBloc,
        super(TurnosState(currentWeekStart: _getStartOfWeek(DateTime.now()))) {
    on<TurnosLoadRequested>(_onLoadRequested);
    on<TurnosWeekChanged>(_onWeekChanged);
    on<TurnoCreated>(_onTurnoCreated);
    on<TurnoSelected>(_onTurnoSelected);
    on<TurnoDeselected>(_onTurnoDeselected);
    on<TurnoDeleted>(_onTurnoDeleted);
    on<TurnoEdited>(_onTurnoEdited);
    on<TurnoStudentAssigned>(_onTurnoStudentAssigned);
    on<TurnoStudentRemoved>(_onTurnoStudentRemoved);
    on<TurnoStudentAttendanceToggled>(_onTurnoStudentAttendanceToggled);
    on<TurnosFilterChanged>(_onFilterChanged);
  }

  void _onFilterChanged(TurnosFilterChanged event, Emitter<TurnosState> emit) {
    emit(state.copyWith(
      selectedInstructor: () => event.instructor,
      selectedRoom: () => event.room,
    ));
  }

  static DateTime _getStartOfWeek(DateTime date) {
    // 1 is Monday
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _onLoadRequested(
    TurnosLoadRequested event,
    Emitter<TurnosState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final start = event.weekStart;
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final startIso = DateFormat('yyyy-MM-dd').format(start);
      final endIso = DateFormat('yyyy-MM-dd').format(end);

      final response = await Supabase.instance.client
          .from('class_sessions')
          .select('*, reservations(id, user_id, status, profiles:profiles!reservations_user_id_fkey(full_name))')
          .gte('date', startIso)
          .lte('date', endIso);

      final sessions = response.map<ClassSession>((data) => ClassSession.fromJson(data)).toList();

      ClassSession? freshSelected;
      if (state.selectedTurno != null) {
        try {
          freshSelected = sessions.firstWhere((s) => s.id == state.selectedTurno!.id);
        } catch (_) {
          freshSelected = state.selectedTurno;
        }
      }

      emit(state.copyWith(
        sessions: sessions,
        selectedTurno: freshSelected,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al cargar turnos: $e',
      ));
    }
  }

  Future<void> _onWeekChanged(
    TurnosWeekChanged event,
    Emitter<TurnosState> emit,
  ) async {
    final startOfWeek = _getStartOfWeek(event.newWeekStart);
    emit(state.copyWith(currentWeekStart: startOfWeek, clearSelection: true));
    add(TurnosLoadRequested(startOfWeek));
  }

  Future<void> _onTurnoCreated(
    TurnoCreated event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      final insertData = <Map<String, dynamic>>[];
      for (int i = 0; i < event.recurrenceWeeks; i++) {
        final d = event.date.add(Duration(days: i * 7));
        final dateIso = DateFormat('yyyy-MM-dd').format(d);

        insertData.add({
          'template_id': event.template.id,
          'name': event.template.name,
          'description': event.template.description,
          'date': dateIso,
          'start_time': event.template.startTime,
          'end_time': event.template.endTime,
          'capacity': event.template.capacity,
          'status': 'scheduled',
          'instructor_name': event.template.instructorName,
        });
      }

      await Supabase.instance.client.from('class_sessions').insert(insertData);
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Turno creado',
        subtitle: '${event.template.name} — ${DateFormat('dd/MM', 'es_ES').format(event.date)}${event.recurrenceWeeks > 1 ? ' (+${event.recurrenceWeeks - 1} recurrencias)' : ''}.',
        category: ActivityCategory.turno,
        timestamp: DateTime.now(),
      )));
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al crear el turno: $e'));
    }
  }

  void _onTurnoSelected(
    TurnoSelected event,
    Emitter<TurnosState> emit,
  ) {
    if (state.selectedTurno?.id == event.turno.id) {
      emit(state.copyWith(clearSelection: true));
    } else {
      emit(state.copyWith(selectedTurno: event.turno));
    }
  }

  void _onTurnoDeselected(
    TurnoDeselected event,
    Emitter<TurnosState> emit,
  ) {
    emit(state.copyWith(clearSelection: true));
  }

  Future<void> _onTurnoDeleted(
    TurnoDeleted event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      await Supabase.instance.client.from('class_sessions').delete().eq('id', event.sessionId);
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Turno cancelado',
        subtitle: 'Se eliminó la sesión del cronograma.',
        category: ActivityCategory.turno,
        timestamp: DateTime.now(),
      )));
      emit(state.copyWith(clearSelection: true));
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al cancelar turno: $e'));
    }
  }

  Future<void> _onTurnoEdited(
    TurnoEdited event,
    Emitter<TurnosState> emit,
  ) async {
    final t = event.turno;
    try {
      final dateIso = DateFormat('yyyy-MM-dd').format(t.date);
      await Supabase.instance.client.from('class_sessions').update({
        'name': t.name,
        'description': t.description,
        'date': dateIso,
        'start_time': t.startTime.substring(0, 5),
        'end_time': t.endTime.substring(0, 5),
        'capacity': t.capacity,
        'instructor_name': t.instructorName,
      }).eq('id', t.id);

      emit(state.copyWith(clearSelection: true));
      add(TurnosLoadRequested(state.currentWeekStart));
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Turno modificado',
        subtitle: '${t.name} actualizado para el ${DateFormat('dd/MM', 'es_ES').format(t.date)}.',
        category: ActivityCategory.turno,
        timestamp: DateTime.now(),
      )));
    } catch (e) {
      emit(state.copyWith(error: 'Error al editar turno: $e'));
    }
  }

  Future<void> _onTurnoStudentAssigned(
    TurnoStudentAssigned event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      final db = Supabase.instance.client;
      final inserts = <Map<String, dynamic>>[];
      
      // 1. Inscripción actual focalizada
      inserts.add({
        'user_id': event.userId,
        'session_id': event.session.id,
        'status': 'confirmed' 
      });

      // 2. Si marcamos recurrencia, buscamos las 3 clases *futuras* con el mismo template
      if (event.enrollInFuture && event.session.templateId != null) {
        final startIso = DateFormat('yyyy-MM-dd').format(event.session.date.add(const Duration(days: 1))); // From tomorrow onwards
        
        final futureSessionsResponse = await db.from('class_sessions')
          .select('id')
          .eq('template_id', event.session.templateId!)
          .gte('date', startIso)
          .order('date', ascending: true)
          .limit(3);

        final futureSessions = futureSessionsResponse as List<dynamic>;
        for (final row in futureSessions) {
          // Omito validación estricta de cupo en inscripciones masivas para hacerlo atómico y resolverlo a nivel logistico si choca.
          inserts.add({
            'user_id': event.userId,
            'session_id': row['id'],
            'status': 'confirmed'
          });
        }
      }

      await db.from('reservations').insert(inserts);
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Alumno inscripto a turno',
        subtitle: 'Inscripción confirmada en ${event.session.name}${event.enrollInFuture ? ' (recurrente)' : ''}.',
        category: ActivityCategory.alumno,
        timestamp: DateTime.now(),
      )));
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al inscribir alumno: $e'));
    }
  }

  Future<void> _onTurnoStudentRemoved(
    TurnoStudentRemoved event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      await Supabase.instance.client.from('reservations').delete().eq('id', event.reservationId);
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Alumno removido de turno',
        subtitle: 'Reserva cancelada y cupo liberado.',
        category: ActivityCategory.turno,
        timestamp: DateTime.now(),
      )));
      // Refrescar el turno seleccionado
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al desinscribir alumno: $e'));
    }
  }

  Future<void> _onTurnoStudentAttendanceToggled(
    TurnoStudentAttendanceToggled event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      final nextStatus = event.currentStatus == 'attended' ? 'confirmed' : 'attended';
      await Supabase.instance.client
          .from('reservations')
          .update({'status': nextStatus})
          .eq('id', event.reservationId);
      
      // Refrescar para ver el cambio
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al marcar asistencia: $e'));
    }
  }
}
