// Modelo sin dependencias de flutter/material

/// Rutina de ejercicios del catálogo de la institución.
class Routine {
  final String id;
  final String name;
  final String? description;
  final List<String> exercises;
  final DateTime createdAt;

  const Routine({
    required this.id,
    required this.name,
    this.description,
    this.exercises = const [],
    required this.createdAt,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      description: json['description'],
      exercises: json['exercises'] != null
          ? List<String>.from(
              (json['exercises'] as List).map((e) => e.toString()))
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Rutina asignada a un alumno (join de routine_assignments con routines).
class RoutineAssignment {
  final String id;
  final String userId;
  final Routine routine;
  final DateTime assignedAt;

  const RoutineAssignment({
    required this.id,
    required this.userId,
    required this.routine,
    required this.assignedAt,
  });

  factory RoutineAssignment.fromJson(Map<String, dynamic> json) {
    return RoutineAssignment(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      routine: Routine.fromJson(json['routines'] ?? const {}),
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Alumno liviano para el listado de rutinas (sin joins pesados).
class RoutineStudent {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isActive;

  const RoutineStudent({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isActive,
  });

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1);
    return parts[0].substring(0, 1) + parts[1].substring(0, 1);
  }

  factory RoutineStudent.fromJson(Map<String, dynamic> json) {
    return RoutineStudent(
      id: json['id'] ?? '',
      name: json['full_name'] ?? 'Sin nombre',
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? false,
    );
  }
}
