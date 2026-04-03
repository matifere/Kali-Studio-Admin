import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/models/turno.dart';

part 'turnos_event.dart';
part 'turnos_state.dart';

/// Gestiona el turno seleccionado en el calendario semanal.
///
/// [TurnoSelected] actúa como toggle: si el turno ya estaba seleccionado,
/// lo deselecciona; si era distinto, selecciona el nuevo.
class TurnosBloc extends Bloc<TurnosEvent, TurnosState> {
  TurnosBloc() : super(const TurnosState()) {
    on<TurnoSelected>(_onTurnoSelected);
    on<TurnoDeselected>(_onTurnoDeselected);
  }

  void _onTurnoSelected(
    TurnoSelected event,
    Emitter<TurnosState> emit,
  ) {
    final isAlreadySelected = state.selectedTurno == event.turno;
    emit(TurnosState(
      selectedTurno: isAlreadySelected ? null : event.turno,
    ));
  }

  void _onTurnoDeselected(
    TurnoDeselected event,
    Emitter<TurnosState> emit,
  ) {
    emit(const TurnosState());
  }
}
