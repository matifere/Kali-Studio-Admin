part of 'turnos_bloc.dart';

abstract class TurnosEvent {}

/// Solicita cargar los turnos para la semana indicada.
class TurnosLoadRequested extends TurnosEvent {
  final DateTime weekStart;
  TurnosLoadRequested(this.weekStart);
}

/// El usuario cambió de semana (avanzar/retroceder).
class TurnosWeekChanged extends TurnosEvent {
  final DateTime newWeekStart;
  TurnosWeekChanged(this.newWeekStart);
}

/// El usuario creó un nuevo turno.
class TurnoCreated extends TurnosEvent {
  final ScheduleTemplate template;
  final DateTime date;
  TurnoCreated({required this.template, required this.date});
}

/// El usuario tocó una tarjeta de turno en el calendario.
/// Si [turno] ya estaba seleccionado, se deselecciona (toggle).
class TurnoSelected extends TurnosEvent {
  final ClassSession turno;

  TurnoSelected(this.turno);
}

/// El usuario cerró el panel de detalle.
class TurnoDeselected extends TurnosEvent {}

/// El usuario cancela (elimina) un turno.
class TurnoDeleted extends TurnosEvent {
  final String sessionId;
  TurnoDeleted(this.sessionId);
}

/// El usuario ha guardado la modificación de un turno.
class TurnoEdited extends TurnosEvent {
  final ClassSession turno;
  TurnoEdited(this.turno);
}

/// Se inscribe a un alumno a un turno
class TurnoStudentAssigned extends TurnosEvent {
  final String userId;
  final String sessionId;
  TurnoStudentAssigned({required this.userId, required this.sessionId});
}

/// Se des-inscribe/remueve a un alumno de un turno
class TurnoStudentRemoved extends TurnosEvent {
  final String reservationId;
  TurnoStudentRemoved(this.reservationId);
}

