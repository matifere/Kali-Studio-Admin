import 'package:flutter/material.dart';

/// Modelo de datos de un alumno.
class Student {
  final String id;
  final String? avatarImage;
  final String name;
  final String email;
  final String plan;
  final bool isActive;
  final String nextShift;
  final String shiftClass;
  final bool reactivate;
  final DateTime createdAt;
  final List<String> patologias;
  final DateTime? planEndDate;
  final int attendedThisMonth;

  const Student({
    required this.id,
    this.avatarImage,
    required this.name,
    required this.email,
    required this.plan,
    required this.isActive,
    required this.nextShift,
    required this.shiftClass,
    required this.createdAt,
    required this.patologias,
    this.planEndDate,
    this.reactivate = false,
    this.attendedThisMonth = 0,
  });
  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1);
    return parts[0].substring(0, 1) + parts[1].substring(0, 1);
  }

  Color get avatarColor {
    List<Color> colores = [Colors.grey, Colors.brown, Colors.white];
    return colores[name.length % colores.length];
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    // 1. Extracción segura del Plan
    // Supabase devuelve los joins como Listas (arrays) de Mapas.
    String currentPlan = 'Sin plan';
    DateTime? endDate;
    if (json['subscriptions'] != null &&
        (json['subscriptions'] as List).isNotEmpty) {
      final subs = json['subscriptions'] as List;
      // Preferir suscripción activa; si no hay, tomar la primera
      final sub = subs.firstWhere(
        (s) => s['status'] == 'active',
        orElse: () => subs.first,
      );
      if (sub['plans'] != null) {
        currentPlan = sub['plans']['name'] ?? 'Sin plan';
      }
      if (sub['end_date'] != null) {
        endDate = DateTime.tryParse(sub['end_date']);
      }
    }

    // 2. Extracción segura del Próximo Turno y Clase
    String nextShiftDate = 'Sin turno asignado';
    String shiftClassName = 'Sin clase';

    if (json['reservations'] != null &&
        (json['reservations'] as List).isNotEmpty) {
      // Asumimos que la query ordena las reservas para que la [0] sea la más próxima
      final firstReservation = json['reservations'][0];

      if (firstReservation['class_sessions'] != null) {
        final session = firstReservation['class_sessions'];
        shiftClassName = session['name'] ??
            session['template_id'] ??
            'Clase'; // Fallback por si no tiene nombre directo

        final date = session['date'];
        final startTime = session['start_time'];

        if (date != null && startTime != null) {
          // Formateo crudo. Luego podrías usar el paquete 'intl' para dejarlo más prolijo.
          nextShiftDate = '$date a las $startTime';
        }
      }
    }

    // 3. Contar asistencias del mes actual
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastOfMonth = DateTime(now.year, now.month + 1, 0);
    int attendedThisMonth = 0;
    if (json['reservations'] != null) {
      for (final r in json['reservations'] as List) {
        if (r['status'] == 'attended' && r['class_sessions'] != null) {
          final dateStr = r['class_sessions']['date'] as String?;
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date != null &&
                !date.isBefore(firstOfMonth) &&
                !date.isAfter(lastOfMonth)) {
              attendedThisMonth++;
            }
          }
        }
      }
    }

    // 4. Retorno de la instancia
    return Student(
      id: json['id'] ?? '',
      avatarImage: json['avatar_url'],
      name: json['full_name'] ?? 'Sin nombre',
      email: json['email'] ?? 'correo@pendiente.com',
      plan: currentPlan,
      isActive: json['is_active'] ?? false,
      nextShift: nextShiftDate,
      shiftClass: shiftClassName,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      patologias: json['patologias'] != null ? List<String>.from(json['patologias']) : [],
      planEndDate: endDate,
      reactivate: false,
      attendedThisMonth: attendedThisMonth,
    );
  }
}
