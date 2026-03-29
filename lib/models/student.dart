import 'package:flutter/material.dart';

/// Modelo de datos de un alumno.
class Student {
  final String initials;
  final Color avatarColor;
  final String? avatarImage;
  final String name;
  final String email;
  final String plan;
  final bool isActive;
  final String nextShift;
  final String shiftClass;
  final bool reactivate;

  const Student({
    required this.initials,
    required this.avatarColor,
    this.avatarImage,
    required this.name,
    required this.email,
    required this.plan,
    required this.isActive,
    required this.nextShift,
    required this.shiftClass,
    this.reactivate = false,
  });
}
