class ScheduleTemplate {
  final String id;
  final String name;
  final String? description;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int capacity;
  final String? instructorName;
  final bool isActive;

  const ScheduleTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.instructorName,
    required this.isActive,
  });

  factory ScheduleTemplate.fromJson(Map<String, dynamic> json) {
    return ScheduleTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      capacity: json['capacity'],
      instructorName: json['instructor_name'],
      isActive: json['is_active'] ?? true,
    );
  }

  /// Helper to convert English day names from DB to index (0 = Lunes)
  int get dayIndex {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday': return 0;
      case 'tuesday': return 1;
      case 'wednesday': return 2;
      case 'thursday': return 3;
      case 'friday': return 4;
      case 'saturday': return 5;
      case 'sunday': return 6;
      default: return 0;
    }
  }

  /// Retorna el nombre del día en Español para la UI
  String get dayNameSpanish {
    switch (dayIndex) {
      case 0: return 'Lunes';
      case 1: return 'Martes';
      case 2: return 'Miércoles';
      case 3: return 'Jueves';
      case 4: return 'Viernes';
      case 5: return 'Sábado';
      case 6: return 'Domingo';
      default: return 'Desconocido';
    }
  }
}
