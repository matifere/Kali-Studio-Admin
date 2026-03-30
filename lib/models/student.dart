import 'package:flutter/material.dart';

/// Modelo de datos de un alumno.
class Student {
  final String? avatarImage;
  final String name;
  final String email;
  final String plan;
  final bool isActive;
  final String nextShift;
  final String shiftClass;
  final bool reactivate;

  const Student({
    this.avatarImage,
    required this.name,
    required this.email,
    required this.plan,
    required this.isActive,
    required this.nextShift,
    required this.shiftClass,
    this.reactivate = false,
  });
  String get initials {
    //si bien puede tener un nombre mas largo (por ejemplo nombre segundo nombre apellido segundo apellido), despues nos complicaria la UI asi que lo voy a dejar asi
    if (name.split(" ").length <= 1) {
      if (name.isEmpty) {
        return "";
      }
      return name.substring(0, 1);
    }
    return name.split(' ')[0].substring(0, 1) +
        name.split(' ')[1].substring(0, 1);
  }

  Color get avatarColor {
    List<Color> colores = [Colors.grey, Colors.brown, Colors.white];
    return colores[name.length % colores.length];
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    // 1. Extracción segura del Plan
    // Supabase devuelve los joins como Listas (arrays) de Mapas.
    String currentPlan = 'Sin plan';
    if (json['subscriptions'] != null &&
        (json['subscriptions'] as List).isNotEmpty) {
      // Tomamos la primera suscripción (idealmente la query la trae filtrada/ordenada por activa)
      final firstSub = json['subscriptions'][0];
      if (firstSub['plans'] != null) {
        currentPlan = firstSub['plans']['name'] ?? 'Sin plan';
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

    // 3. Retorno de la instancia
    return Student(
      avatarImage: json['avatar_url'],
      name: json['full_name'] ?? 'Sin nombre',
      // NOTA: Como vimos en el diagrama, email no está en profiles.
      // Deberás agregarlo a la tabla o crear una vista (view) en SQL que una auth.users con profiles.
      email: json['email'] ?? 'correo@pendiente.com',
      plan: currentPlan,
      isActive: json['is_active'] ?? false,
      nextShift: nextShiftDate,
      shiftClass: shiftClassName,
      reactivate:
          false, // Asumo que esto es puramente para la UI y no viene de la DB
    );
  }
}
