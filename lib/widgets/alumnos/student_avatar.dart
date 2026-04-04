import 'package:flutter/material.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/avatar_provider.dart';

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
      final provider = AvatarProvider.fromUrl(student.avatarImage);
      if (provider != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: student.avatarColor,
          backgroundImage: provider,
        );
      }
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
