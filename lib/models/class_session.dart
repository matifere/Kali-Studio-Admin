import 'package:flutter/material.dart';
import 'package:kali_studio/models/turno.dart';

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
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    // Check for reservations array to calculate `enrolled`
    int enrolledCount = 0;
    if (json['reservations'] != null && json['reservations'] is List) {
      enrolledCount = (json['reservations'] as List).length;
    }

    return ClassSession(
      id: json['id'],
      templateId: json['template_id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      capacity: json['capacity'],
      status: json['status'],
      cancellationReason: json['cancellation_reason'],
      instructorName: json['instructor_name'],
      enrolled: enrolledCount,
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

  /// Parses HH:mm formatted strings into a TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
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

  Color get backgroundColor {
    switch (uiTurnoType) {
      case TurnoType.reformerPilates:
        return const Color(0xFFF5D9B8); // Clay/peach cálido
      case TurnoType.matPilates:
        return const Color(0xFFEDE6D8); // Sand suave
      case TurnoType.privateSpecial:
        return const Color(0xFF2C1F14); // Espresso oscuro
    }
  }

  Color get foregroundColor {
    switch (uiTurnoType) {
      case TurnoType.reformerPilates:
      case TurnoType.matPilates:
        return const Color(0xFF2C1F14); // Espresso
      case TurnoType.privateSpecial:
        return const Color(0xFFFAF7F2); // Warm white
    }
  }
}
