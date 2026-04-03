part of 'turnos_bloc.dart';

abstract class TurnosEvent {}

/// El usuario tocó una tarjeta de turno en el calendario.
/// Si [turno] ya estaba seleccionado, se deselecciona (toggle).
class TurnoSelected extends TurnosEvent {
  final Turno turno;

  TurnoSelected(this.turno);
}

/// El usuario cerró el panel de detalle.
class TurnoDeselected extends TurnosEvent {}
