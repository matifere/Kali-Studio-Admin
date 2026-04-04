import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/models/schedule_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

part 'turnos_event.dart';
part 'turnos_state.dart';

class TurnosBloc extends Bloc<TurnosEvent, TurnosState> {
  TurnosBloc() : super(TurnosState(currentWeekStart: _getStartOfWeek(DateTime.now()))) {
    on<TurnosLoadRequested>(_onLoadRequested);
    on<TurnosWeekChanged>(_onWeekChanged);
    on<TurnoCreated>(_onTurnoCreated);
    on<TurnoSelected>(_onTurnoSelected);
    on<TurnoDeselected>(_onTurnoDeselected);
    on<TurnoDeleted>(_onTurnoDeleted);
    on<TurnoEdited>(_onTurnoEdited);
    on<TurnoStudentAssigned>(_onTurnoStudentAssigned);
    on<TurnoStudentRemoved>(_onTurnoStudentRemoved);
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
          .select('*, reservations(id, user_id, profiles:profiles!reservations_user_id_fkey(full_name, avatar_url))')
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
      final dateIso = DateFormat('yyyy-MM-dd').format(event.date);

      await Supabase.instance.client.from('class_sessions').insert({
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
    } catch (e) {
      emit(state.copyWith(error: 'Error al editar turno: $e'));
    }
  }

  Future<void> _onTurnoStudentAssigned(
    TurnoStudentAssigned event,
    Emitter<TurnosState> emit,
  ) async {
    try {
      await Supabase.instance.client.from('reservations').insert({
        'user_id': event.userId,
        'session_id': event.sessionId,
        'status': 'confirmed' // Assuming confirmed is the default reservation_status
      });

      // Refrescar el turno seleccionado para mostrar el alumno
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
      
      // Refrescar el turno seleccionado
      add(TurnosLoadRequested(state.currentWeekStart));
    } catch (e) {
      emit(state.copyWith(error: 'Error al desinscribir alumno: $e'));
    }
  }
}
