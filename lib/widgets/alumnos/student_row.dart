import 'package:flutter/material.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_avatar.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/common/kali_plan_badge.dart';

/// Fila de la tabla que representa a un alumno.
class StudentRow extends StatefulWidget {
  final Student student;
  const StudentRow({super.key, required this.student});

  @override
  State<StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<StudentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.bounceInOut,
        color: _hovered ? KaliColors.warmWhite : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Row(
          children: [
            // Nombre + avatar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  StudentAvatar(student: s),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: KaliText.body(
                          KaliColors.espresso,
                          weight: FontWeight.w600,
                          size: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.email,
                        style: KaliText.body(
                          KaliColors.espresso.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Plan badge
            Expanded(
              flex: 3,
              child: KaliPlanBadge(plan: s.plan),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: _StatusIndicator(isActive: s.isActive),
            ),

            // Próximo turno
            Expanded(
              flex: 3,
              child: _ShiftInfo(
                nextShift: s.nextShift,
                shiftClass: s.shiftClass,
                reactivate: s.reactivate,
              ),
            ),

            // Acciones
            const Expanded(
              flex: 2,
              child: Row(
                children: [
                  KaliIconButton.action(
                    Icons.visibility_outlined,
                    tooltip: 'Ver perfil',
                  ),
                  SizedBox(width: 4),
                  KaliIconButton.action(
                    Icons.edit_outlined,
                    tooltip: 'Editar',
                  ),
                  SizedBox(width: 4),
                  KaliIconButton.action(
                    Icons.more_horiz,
                    tooltip: 'Más opciones',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Indicador de estado ──────────────────────────────────────────────────────
class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  const _StatusIndicator({required this.isActive});

  static const _activeColor = Color(0xFF5C9E6C);
  static const _inactiveColor = Color(0xFFD4685C);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _activeColor : _inactiveColor;

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? 'Activo' : 'Inactivo',
          style: KaliText.body(color, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Info del próximo turno ───────────────────────────────────────────────────
class _ShiftInfo extends StatelessWidget {
  final String nextShift;
  final String shiftClass;
  final bool reactivate;

  const _ShiftInfo({
    required this.nextShift,
    required this.shiftClass,
    required this.reactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nextShift,
          style: KaliText.body(
            reactivate
                ? KaliColors.espresso.withValues(alpha: 0.4)
                : KaliColors.espresso,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          shiftClass,
          style: KaliText.label(
            reactivate
                ? const Color(0xFFD4685C)
                : KaliColors.espresso.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
