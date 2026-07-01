// Modelo puro, sin dependencias de UI

/// Tipo de clase para determinar el color de la tarjeta.
enum TurnoType {
  reformerPilates,
  matPilates,
  privateSpecial,
}

/// Modelo de datos de un turno (clase agendada).
class Turno {
  final String className;
  final String instructor;
  final int dayIndex; // 0 = Lun, 1 = Mar, ..., 4 = Vie
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final int enrolled;
  final int capacity;
  final TurnoType type;
  final List<TurnoAttendee> attendees;

  const Turno({
    required this.className,
    required this.instructor,
    required this.dayIndex,
    required this.startHour,
    this.startMinute = 0,
    required this.durationMinutes,
    required this.enrolled,
    required this.capacity,
    required this.type,
    this.attendees = const [],
  });

  /// Hora de inicio formateada.
  String get startTimeFormatted {
    final h = startHour.toString().padLeft(2, '0');
    final m = startMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Hora de fin formateada.
  String get endTimeFormatted {
    final totalMin = startHour * 60 + startMinute + durationMinutes;
    final h = (totalMin ~/ 60).toString().padLeft(2, '0');
    final m = (totalMin % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Texto de ocupación (ej: "5/6 full").
  String get occupancyText => '$enrolled/$capacity';

  /// Si está lleno.
  bool get isFull => enrolled >= capacity;

  // UI colors (backgroundColor, foregroundColor) were removed to UI layer.
}

/// Asistente de un turno.
class TurnoAttendee {
  final String initials;
  final String name;

  const TurnoAttendee({
    required this.initials,
    required this.name,
  });
}
