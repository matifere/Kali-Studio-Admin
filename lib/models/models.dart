// ─── Modelo: Clase de pilates ─────────────────────────────────────────────────
class PilatesClass {
  final String id;
  final String name;
  final String instructor;
  final String time;       // e.g. "07:30"
  final String period;     // "AM" / "PM"
  final String room;
  final String level;
  final int durationMin;
  final int totalSpots;
  final int takenSpots;
  final String equipment;
  final String description;
  final bool isBooked;

  const PilatesClass({
    required this.id,
    required this.name,
    required this.instructor,
    required this.time,
    required this.period,
    required this.room,
    required this.level,
    required this.durationMin,
    required this.totalSpots,
    required this.takenSpots,
    required this.equipment,
    required this.description,
    this.isBooked = false,
  });

  int get availableSpots => totalSpots - takenSpots;
}

// ─── Modelo: Instructor ───────────────────────────────────────────────────────
class Instructor {
  final String name;
  final String initials;
  final String certification;
  final int yearsExp;
  final String bio;

  const Instructor({
    required this.name,
    required this.initials,
    required this.certification,
    required this.yearsExp,
    required this.bio,
  });
}

// ─── Datos de ejemplo ─────────────────────────────────────────────────────────
class KaliData {
  static const List<PilatesClass> todayClasses = [
    PilatesClass(
      id: '1',
      name: 'Reformer Intermedio',
      instructor: 'Luciana Paz',
      time: '7:30', period: 'AM',
      room: 'Sala 2', level: 'Intermedio',
      durationMin: 55, totalSpots: 8, takenSpots: 8,
      equipment: 'Reformer',
      description: 'Clase de reformer para alumnas con base sólida. Trabajamos '
          'coordinación, control y fluidez de movimiento con secuencias dinámicas.',
      isBooked: true,
    ),
    PilatesClass(
      id: '2',
      name: 'Mat Pilates Flow',
      instructor: 'Sofía Ríos',
      time: '10:00', period: 'AM',
      room: 'Sala 1', level: 'Todos los niveles',
      durationMin: 50, totalSpots: 10, takenSpots: 6,
      equipment: 'Mat',
      description: 'Clase fluida en mat que combina principios clásicos del pilates '
          'con elementos de movilidad. Ideal para todos los niveles.',
    ),
    PilatesClass(
      id: '3',
      name: 'Pilates Restaurativo',
      instructor: 'Camila Ortiz',
      time: '12:00', period: 'PM',
      room: 'Sala 3', level: 'Principiante',
      durationMin: 60, totalSpots: 8, takenSpots: 0,
      equipment: 'Mat + accesorios',
      description: 'Sesión de pilates suave enfocada en recuperación, respiración '
          'y reconexión corporal. Perfecta para comenzar o como descanso activo.',
    ),
    PilatesClass(
      id: '4',
      name: 'Reformer Avanzado',
      instructor: 'Luciana Paz',
      time: '6:30', period: 'PM',
      room: 'Sala 2', level: 'Avanzado',
      durationMin: 55, totalSpots: 8, takenSpots: 6,
      equipment: 'Reformer',
      description: 'Clase de alta intensidad diseñada para alumnas con sólida base. '
          'Trabajaremos fuerza, control y precisión con variaciones avanzadas.',
    ),
  ];

  static const Instructor luciana = Instructor(
    name: 'Luciana Paz',
    initials: 'LP',
    certification: 'STOTT Pilates certificada',
    yearsExp: 8,
    bio: 'Especialista en reformer y Pilates clínico. Formada en Buenos Aires y '
        'certificada internacionalmente por STOTT. Su enfoque combina técnica '
        'precisa con una mirada holística del movimiento.',
  );
}
