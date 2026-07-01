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
  final String? groupId;
  final String? institutionId;
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
    this.groupId,
    this.institutionId,
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
      groupId: json['group_id'],
      institutionId: json['institution_id'],
      name: json['name'] ?? 'Sin Nombre',
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? '00:00',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? 'scheduled',
      cancellationReason: json['cancellation_reason'],
      instructorName: json['instructor_name'],
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

  // UI colors logic was removed. Handled by ThemeExtension in UI based on name.hashCode.
}
