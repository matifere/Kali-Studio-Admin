import 'package:flutter/material.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/avatar_provider.dart';

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
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final avatarColors = [kaliColors.clay, kaliColors.sand, kaliColors.sage];
    final avatarColor = avatarColors[student.name.length % avatarColors.length];

    if (student.avatarImage != null && student.avatarImage!.isNotEmpty) {
      final provider = AvatarProvider.fromUrl(student.avatarImage);
      if (provider != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: avatarColor,
          backgroundImage: provider,
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      child: Text(
        student.initials,
        style: kaliColors.body(
          kaliColors.espresso,
          weight: FontWeight.w700,
          size: radius * 0.6,
        ),
      ),
    );
  }
}
