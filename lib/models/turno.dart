import 'package:flutter/material.dart';

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

  /// Color de fondo de la tarjeta basado en tipo.
  Color get backgroundColor {
    switch (type) {
      case TurnoType.reformerPilates:
        return const Color(0xFFF5D9B8); // Clay/peach cálido
      case TurnoType.matPilates:
        return const Color(0xFFEDE6D8); // Sand suave
      case TurnoType.privateSpecial:
        return const Color(0xFF2C1F14); // Espresso oscuro
    }
  }

  /// Color de texto basado en tipo.
  Color get foregroundColor {
    switch (type) {
      case TurnoType.reformerPilates:
      case TurnoType.matPilates:
        return const Color(0xFF2C1F14); // Espresso
      case TurnoType.privateSpecial:
        return const Color(0xFFFAF7F2); // Warm white
    }
  }
}

/// Asistente de un turno.
class TurnoAttendee {
  final String initials;
  final Color avatarColor;
  final String name;

  const TurnoAttendee({
    required this.initials,
    required this.avatarColor,
    required this.name,
  });
}
