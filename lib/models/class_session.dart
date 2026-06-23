import 'package:flutter/material.dart';
import 'package:argrity/models/turno.dart';
class TurnoReservation {
  final String id;
  final String userId;
  final String studentName;
  final String status;

  const TurnoReservation({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.status,
  });

  factory TurnoReservation.fromJson(Map<String, dynamic> json) {
    String name = 'Sin nombre';
    if (json['profiles'] != null) {
      name = json['profiles']['full_name'] ?? 'Sin nombre';
    }

    return TurnoReservation(
      id: json['id'],
      userId: json['user_id'],
      studentName: name,
      status: json['status'] ?? 'confirmed',
    );
  }
}

class ClassSession {
  final String id;
  final String? templateId;
  final String name;
  final String? description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int capacity;
  final String status;
  final String? cancellationReason;
  final String? instructorName;
  final int enrolled;
  final List<TurnoReservation> enrolledStudents;

  const ClassSession({
    required this.id,
    this.templateId,
    required this.name,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.status,
    this.cancellationReason,
    this.instructorName,
    required this.enrolled,
    this.enrolledStudents = const [],
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    List<TurnoReservation> reservations = [];
    if (json['reservations'] != null && json['reservations'] is List) {
      reservations = (json['reservations'] as List)
          .where((r) => (r['status'] as String?) != 'cancelled')
          .map((r) => TurnoReservation.fromJson(r))
          .toList();
    }

    return ClassSession(
      id: json['id'],
      templateId: json['template_id'],
      name: json['name'] ?? json['schedule_templates']?['name'] ?? 'Sin Nombre',
      description: json['description'] ?? json['schedule_templates']?['description'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? json['schedule_templates']?['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? json['schedule_templates']?['end_time'] ?? '00:00',
      capacity: json['capacity'] ?? json['schedule_templates']?['capacity'] ?? 0,
      status: json['status'] ?? 'scheduled',
      cancellationReason: json['cancellation_reason'],
      instructorName: json['instructor_name'] ?? json['schedule_templates']?['instructor_name'],
      enrolled: reservations.length,
      enrolledStudents: reservations,
    );
  }

  /// Converts this ClassSession to a TurnoType for UI color matching.
  TurnoType get uiTurnoType {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('reformer')) {
      return TurnoType.reformerPilates;
    } else if (lowerName.contains('mat') || lowerName.contains('piso')) {
      return TurnoType.matPilates;
    } else {
      return TurnoType.privateSpecial;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  /// Returns Start TimeOfDay
  TimeOfDay get parsedStartTime => _parseTime(startTime);

  /// Returns End TimeOfDay
  TimeOfDay get parsedEndTime => _parseTime(endTime);

  /// Day index (0 = Monday, ..., 6 = Sunday)
  int get dayIndex => date.weekday - 1;

  /// Compatibility with Turno getters
  String get startTimeFormatted {
    final parts = startTime.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  String get endTimeFormatted {
    final parts = endTime.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  String get occupancyText => '$enrolled/$capacity';
  bool get isFull => enrolled >= capacity;

  static const _palette = [
    ColorPair(Color(0xFFF5D9B8), Color(0xFF2C1F14)), // Peach cálido -> Espresso
    ColorPair(Color(0xFFEDE6D8), Color(0xFF2C1F14)), // Sand suave -> Espresso
    ColorPair(Color(0xFFD4DDD3), Color(0xFF2C1F14)), // Sage light -> Espresso
    ColorPair(Color(0xFF2C1F14), Color(0xFFFAF7F2)), // Espresso oscuro -> Blanco cálido
    ColorPair(Color(0xFF8A9E88), Color(0xFFFAF7F2)), // Sage -> Blanco cálido
    ColorPair(Color(0xFFA08060), Color(0xFFFAF7F2)), // Clay dark -> Blanco cálido
    ColorPair(Color(0xFFE8E2D8), Color(0xFF2C1F14)), // Background base -> Espresso
  ];

  ColorPair get _assignedColors {
    // Calculamos un índice dependiente únicamente del nombre de la clase
    final hash = name.trim().toLowerCase().hashCode;
    return _palette[hash.abs() % _palette.length];
  }

  Color get backgroundColor => _assignedColors.bg;
  Color get foregroundColor => _assignedColors.fg;
}

class ColorPair {
  final Color bg;
  final Color fg;
  const ColorPair(this.bg, this.fg);
}
