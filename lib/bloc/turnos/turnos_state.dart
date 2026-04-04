part of 'turnos_bloc.dart';

/// Estado del calendario de turnos.
class TurnosState {
  final List<ClassSession> sessions;
  /// La fecha representa siempre al lunes de la semana focalizada.
  final DateTime currentWeekStart;
  final bool isLoading;
  final String? error;

  /// El turno actualmente seleccionado, o [null] si ninguno lo está.
  final ClassSession? selectedTurno;

  const TurnosState({
    this.sessions = const [],
    required this.currentWeekStart,
    this.isLoading = true,
    this.error,
    this.selectedTurno,
  });

  bool get hasSelection => selectedTurno != null;

  TurnosState copyWith({
    List<ClassSession>? sessions,
    DateTime? currentWeekStart,
    bool? isLoading,
    String? error,
    ClassSession? selectedTurno,
    bool clearSelection = false,
  }) {
    return TurnosState(
      sessions: sessions ?? this.sessions,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedTurno: clearSelection ? null : (selectedTurno ?? this.selectedTurno),
    );
  }
}

