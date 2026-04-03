part of 'turnos_bloc.dart';

/// Estado del calendario de turnos.
class TurnosState {
  /// El turno actualmente seleccionado, o [null] si ninguno lo está.
  final Turno? selectedTurno;

  const TurnosState({this.selectedTurno});

  bool get hasSelection => selectedTurno != null;
}
