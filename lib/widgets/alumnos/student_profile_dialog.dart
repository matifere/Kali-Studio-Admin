import 'package:flutter/material.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_avatar.dart';
import 'package:kali_studio/widgets/common/kali_plan_badge.dart';

class StudentProfileDialog extends StatelessWidget {
  final Student student;

  const StudentProfileDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StudentAvatar(student: student, radius: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: KaliText.headingItalic(KaliColors.espresso, size: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.email,
                          style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: KaliColors.espresso),
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
            _buildInfoRow('Próximo Turno', student.nextShift),
            const SizedBox(height: 12),
            _buildInfoRow('Clase Asignada', student.shiftClass),
            const SizedBox(height: 12),
            _buildInfoRow('Fecha de Ingreso', student.createdAt.toIso8601String().split('T')[0]),
            const SizedBox(height: 24),
            Text(
              'Patologías',
              style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            student.patologias.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student.patologias.map((p) => _buildPatologiaChip(p)).toList(),
                  )
                : Text(
                    'No hay patologías registradas.',
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
        ),
        Text(
          value,
          style: KaliText.body(KaliColors.espresso, weight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPatologiaChip(String patologia) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KaliColors.clayDark.withValues(alpha: 0.3)),
      ),
      child: Text(
        patologia,
        style: KaliText.label(KaliColors.espresso),
      ),
    );
  }
}
