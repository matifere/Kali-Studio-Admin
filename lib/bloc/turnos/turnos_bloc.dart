import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/activity/activity_bloc.dart';
import 'package:argrity/models/class_session.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

part 'turnos_event.dart';
part 'turnos_state.dart';

class TurnosBloc extends Bloc<TurnosEvent, TurnosState> {
  final ActivityBloc? _activityBloc;

  // Cached from the first profile fetch — avoids a round-trip on every week
  // change and every create/assign operation.
  String? _cachedInstId;
  bool _profileCached = false;

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
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _onLoadRequested(
    TurnosLoadRequested event,
    Emitter<TurnosState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final start = event.weekStart;
      final end = start
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final startIso = DateFormat('yyyy-MM-dd').format(start);
      final endIso = DateFormat('yyyy-MM-dd').format(end);

      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (!_profileCached && userId != null) {
        final profile = await client
            .from('profiles')
            .select('role, full_name, institution_id')
            .eq('id', userId)
            .maybeSingle();
        _cachedInstId = profile?['institution_id'] as String?;
        _profileCached = true;
      }
      // instructorFilter is used by the UI filter dropdown now, not automatically for admins.
      final instructorFilter = state.selectedInstructor;

      const sessionSelect =
          '*, '
          'reservations(id, user_id, status, profiles:profiles!reservations_user_id_fkey(full_name))';

      var query = client
          .from('class_sessions')
          .select(sessionSelect)
          .gte('date', startIso)
          .lte('date', endIso);

      if (_cachedInstId != null) {
        query = query.eq('institution_id', _cachedInstId!);
      }

      final response = instructorFilter != null
          ? await query.eq('instructor_name', instructorFilter)
          : await query;

      final sessions = response
          .map<ClassSession>((data) => ClassSession.fromJson(data))
          .toList();

      ClassSession? freshSelected;
      if (state.selectedTurno != null) {
        try {
          freshSelected =
              sessions.firstWhere((s) => s.id == state.selectedTurno!.id);
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

  String _generateUuid() {
    final random = Random();
    final list = List<int>.generate(16, (i) => random.nextInt(256));
    list[6] = (list[6] & 0x0f) | 0x40;
    list[8] = (list[8] & 0x3f) | 0x80;
    final hex = list.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> _onTurnoCreated(
    TurnoCreated event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      final instId = _cachedInstId;

      final insertData = <Map<String, dynamic>>[];
      final String groupId = _generateUuid();

      for (final dayIndex in event.daysOfWeek) {
        var baseDate = state.currentWeekStart.add(Duration(days: dayIndex));
        
        final parts = event.startTime.split(':');
        var startDateTime = DateTime(baseDate.year, baseDate.month,
            baseDate.day, int.parse(parts[0]), int.parse(parts[1]));

        // Si la hora en la semana actual ya pasó, agendar desde la próxima semana
        if (startDateTime.isBefore(DateTime.now())) {
          baseDate = baseDate.add(const Duration(days: 7));
        }

        for (int i = 0; i < event.recurrenceWeeks; i++) {
          final d = baseDate.add(Duration(days: i * 7));
          final dateIso = DateFormat('yyyy-MM-dd').format(d);

          insertData.add({
            'group_id': groupId,
            'name': event.name,
            'description': event.description,
            'instructor_name': event.instructorName,
            'capacity': event.capacity,
            'start_time': event.startTime,
            'end_time': event.endTime,
            'date': dateIso,
            'status': 'scheduled',
            if (instId != null) 'institution_id': instId,
          });
        }
      }

      await Supabase.instance.client.from('class_sessions').insert(insertData);

      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Clase grupal creada',
        subtitle:
            '${event.name} agendado para ${event.recurrenceWeeks} semanas.',
        category: ActivityCategory.turno,
        timestamp: DateTime.now(),
      )));
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al crear la clase: $e'));
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
      if (event.deleteAllFuture) {
        final dateIso = DateFormat('yyyy-MM-dd').format(event.session.date);
        final endOfYearIso = '${event.session.date.year}-12-31';

        await Supabase.instance.client
            .from('class_sessions')
            .delete()
            .eq('group_id', event.session.groupId!)
            .gte('date', dateIso)
            .lte('date', endOfYearIso);

        _activityBloc?.add(ActivityLogged(ActivityEntry(
          title: 'Serie de turnos cancelada',
          subtitle: 'Se eliminaron las clases de ${event.session.name} hasta fin de año.',
          category: ActivityCategory.turno,
          timestamp: DateTime.now(),
        )));
      } else {
        await Supabase.instance.client
            .from('class_sessions')
            .delete()
            .eq('id', event.session.id);

        _activityBloc?.add(ActivityLogged(ActivityEntry(
          title: 'Turno cancelado',
          subtitle: 'Se eliminó la sesión del cronograma.',
          category: ActivityCategory.turno,
          timestamp: DateTime.now(),
        )));
      }

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
      if (event.editFutureSessions && t.groupId != null) {
        final dateIso = DateFormat('yyyy-MM-dd').format(t.date);
        final endOfYearIso = '${t.date.year}-12-31';

        await Supabase.instance.client.from('class_sessions').update({
          'name': t.name,
          'description': t.description,
          'start_time': t.startTime.substring(0, 5),
          'end_time': t.endTime.substring(0, 5),
          'capacity': t.capacity,
          'instructor_name': t.instructorName,
        }).eq('group_id', t.groupId!)
          .gte('date', dateIso)
          .lte('date', endOfYearIso);
      } else {
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
      }

      emit(state.copyWith(clearSelection: true));
      add(TurnosLoadRequested(state.currentWeekStart));
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Turno modificado',
        subtitle:
            '${t.name} actualizado para el ${DateFormat('dd/MM', 'es_ES').format(t.date)}.',
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
        'status': 'confirmed',
      });

      // 2. Si marcamos recurrencia, buscamos las clases futuras con el mismo template
      if (event.enrollmentType != EnrollmentType.single && event.session.groupId != null) {
        final startIso = DateFormat('yyyy-MM-dd').format(event.session.date
            .add(const Duration(days: 1))); // From tomorrow onwards

        // Fetch max reservations limit for the user
        final subRes = await db
            .from('subscriptions')
            .select('plans(max_reservations_per_month)')
            .eq('user_id', event.userId)
            .inFilter('status', ['active', 'pending']).maybeSingle();

        int maxRes = 0;
        if (subRes != null &&
            subRes['plans'] != null &&
            subRes['plans']['max_reservations_per_month'] != null) {
          maxRes = subRes['plans']['max_reservations_per_month'] as int;
        }

        // Only project if maxRes > 0
        if (maxRes > 0) {
          final limitCount = event.enrollmentType == EnrollmentType.month ? 3 : 52;
          final futureSessionsResponse = await db
              .from('class_sessions')
              .select('id, date')
              .eq('group_id', event.session.groupId!)
              .gte('date', startIso)
              .order('date', ascending: true)
              .limit(limitCount);

          final futureSessions = futureSessionsResponse as List<dynamic>;

          if (futureSessions.isNotEmpty) {
            // Fetch user's existing future reservations to count per month
            final futureRes = await db
                .from('reservations')
                .select('class_sessions!inner(date)')
                .eq('user_id', event.userId)
                .gte('class_sessions.date', startIso);

            DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

            final Map<DateTime, int> resCount = {};
            for (var r in futureRes as List<dynamic>) {
              final d = DateTime.parse(r['class_sessions']['date']);
              final som = startOfMonth(d);
              resCount[som] = (resCount[som] ?? 0) + 1;
            }

            for (final row in futureSessions) {
              final sessionDate = DateTime.parse(row['date']);
              final som = startOfMonth(sessionDate);
              final currCount = resCount[som] ?? 0;

              if (currCount < maxRes) {
                inserts.add({
                  'user_id': event.userId,
                  'session_id': row['id'],
                  'status': 'confirmed',
                });
                resCount[som] = currCount + 1;
              }
            }
          }
        }
      }

      await db.from('reservations').insert(inserts);
      _activityBloc?.add(ActivityLogged(ActivityEntry(
        title: 'Alumno inscripto a turno',
        subtitle:
            'Inscripción confirmada en ${event.session.name}${event.enrollmentType != EnrollmentType.single ? ' (recurrente)' : ''}.',
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
      await Supabase.instance.client
          .from('reservations')
          .delete()
          .eq('id', event.reservationId);
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
      final nextStatus =
          event.currentStatus == 'attended' ? 'confirmed' : 'attended';
      await Supabase.instance.client
          .from('reservations')
          .update({'status': nextStatus}).eq('id', event.reservationId);

      // Refrescar para ver el cambio
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al marcar asistencia: $e'));
    }
  }
}
