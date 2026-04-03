import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Avatar circular de un alumno.
///
/// Muestra la imagen de perfil si la tiene, o las iniciales sobre
/// un fondo de color.
class StudentAvatar extends StatelessWidget {
  final Student student;
  final double radius;

  const StudentAvatar({
    super.key,
    required this.student,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (student.avatarImage != null && student.avatarImage!.isNotEmpty) {
      ImageProvider provider;
      if (student.avatarImage!.startsWith('data:image')) {
        final commaIndex = student.avatarImage!.indexOf(',');
        if (commaIndex != -1) {
          final base64String = student.avatarImage!.substring(commaIndex + 1);
          provider = MemoryImage(base64Decode(base64String));
        } else {
          provider = MemoryImage(base64Decode(student.avatarImage!)); // Fallback in case it's pure base64
        }
      } else {
        provider = NetworkImage(student.avatarImage!);
      }

      return CircleAvatar(
        radius: radius,
        backgroundColor: student.avatarColor,
        backgroundImage: provider,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: student.avatarColor,
      child: Text(
        student.initials,
        style: KaliText.body(
          KaliColors.espresso,
          weight: FontWeight.w700,
          size: radius * 0.6,
        ),
      ),
    );
  }
}
