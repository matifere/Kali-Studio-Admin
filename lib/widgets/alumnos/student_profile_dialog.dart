import 'package:flutter/material.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/alumnos/student_avatar.dart';
import 'package:argrity/widgets/common/kali_plan_badge.dart';

class StudentProfileDialog extends StatelessWidget {
  final Student student;

  const StudentProfileDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      StudentAvatar(student: student, radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: KaliText.headingItalic(kaliColors.espresso, size: 24),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.email,
                              style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: kaliColors.espresso),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                KaliPlanBadge(plan: student.plan),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: student.isActive
                        ? const Color(0xFF5C9E6C).withValues(alpha: 0.1)
                        : const Color(0xFFD4685C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.isActive ? 'Activo' : 'Inactivo',
                    style: KaliText.label(
                      student.isActive ? const Color(0xFF5C9E6C) : const Color(0xFFD4685C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Próximo Turno', student.nextShift, kaliColors),
            const SizedBox(height: 12),
            _buildInfoRow('Clase Asignada', student.shiftClass, kaliColors),
            const SizedBox(height: 12),
            _buildInfoRow('Fecha de Ingreso', student.createdAt.toIso8601String().split('T')[0], kaliColors),
            const SizedBox(height: 24),
            Text(
              'Patologías',
              style: KaliText.body(kaliColors.espresso, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            student.patologias.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student.patologias.map((p) => _buildPatologiaChip(p, kaliColors)).toList(),
                  )
                : Text(
                    'No hay patologías registradas.',
                    style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.5)),
                  ),
          ],
        )),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, KaliColorsExtension kaliColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.5)),
        ),
        Text(
          value,
          style: KaliText.body(kaliColors.espresso, weight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPatologiaChip(String patologia, KaliColorsExtension kaliColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kaliColors.sand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kaliColors.clayDark.withValues(alpha: 0.3)),
      ),
      child: Text(
        patologia,
        style: KaliText.label(kaliColors.espresso),
      ),
    );
  }
}
