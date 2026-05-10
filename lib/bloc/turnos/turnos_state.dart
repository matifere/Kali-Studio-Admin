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

  final String? selectedInstructor;
  final String? selectedRoom;

  const TurnosState({
    this.sessions = const [],
    required this.currentWeekStart,
    this.isLoading = true,
    this.error,
    this.selectedTurno,
    this.selectedInstructor,
    this.selectedRoom,
  });

  bool get hasSelection => selectedTurno != null;

  List<String> get availableInstructors {
    final instructors = sessions
        .map((s) => s.instructorName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    instructors.sort();
    return instructors;
  }

  List<String> get availableRooms {
    final rooms = sessions
        .map((s) => s.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    rooms.sort();
    return rooms;
  }

  List<ClassSession> get filteredSessions {
    return sessions.where((s) {
      if (selectedInstructor != null && selectedInstructor!.isNotEmpty) {
        if (s.instructorName != selectedInstructor) return false;
      }
      if (selectedRoom != null && selectedRoom!.isNotEmpty) {
        if (s.name != selectedRoom) return false;
      }
      return true;
    }).toList();
  }

  TurnosState copyWith({
    List<ClassSession>? sessions,
    DateTime? currentWeekStart,
    bool? isLoading,
    String? error,
    ClassSession? selectedTurno,
    bool clearSelection = false,
    String? Function()? selectedInstructor,
    String? Function()? selectedRoom,
  }) {
    return TurnosState(
      sessions: sessions ?? this.sessions,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedTurno: clearSelection ? null : (selectedTurno ?? this.selectedTurno),
      selectedInstructor: selectedInstructor != null ? selectedInstructor() : this.selectedInstructor,
      selectedRoom: selectedRoom != null ? selectedRoom() : this.selectedRoom,
    );
  }
}

