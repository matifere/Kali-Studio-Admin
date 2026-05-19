import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_avatar.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/alumnos/student_profile_dialog.dart';
import 'package:kali_studio/widgets/alumnos/edit_student_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fila de la tabla que representa a un alumno.
class StudentRow extends StatefulWidget {
  final Student student;
  const StudentRow({super.key, required this.student});

  @override
  State<StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<StudentRow> {
  bool _hovered = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar alumno', style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600, size: 18)),
        content: Text(
          '¿Seguro que querés eliminar a ${widget.student.name}? Esta acción no se puede deshacer.',
          style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: KaliText.body(KaliColors.espresso)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Eliminar', style: KaliText.body(const Color(0xFFD4685C), weight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final deleted = await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', widget.student.id)
            .select('id');

        if (deleted.isEmpty) {
          throw Exception('No se eliminó ningún registro. Agregá esta política en Supabase SQL Editor:\n\nCREATE POLICY "Sudo elimina perfiles" ON profiles FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = \'sudo\'));');
        }

        if (context.mounted) {
          context.read<AlumnosBloc>().add(AlumnosLoadRequested());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alumno eliminado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar alumno: $e'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return MouseRegion(
      onEnter: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true); },
      onExit: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false); },
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600, size: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.email,
                          style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Patologías
            Expanded(
              flex: 3,
              child: _PatologiasCell(patologias: s.patologias),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: _StatusIndicator(isActive: s.isActive),
            ),

            // Asistencias este mes
            Expanded(
              flex: 2,
              child: _AttendanceCell(count: s.attendedThisMonth),
            ),

            // Próximo turno
            Expanded(
              flex: 2,
              child: _ShiftInfo(
                nextShift: s.nextShift,
                shiftClass: s.shiftClass,
                reactivate: s.reactivate,
              ),
            ),

            // Acciones
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  KaliIconButton.action(
                    Icons.visibility_outlined,
                    tooltip: 'Ver perfil',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => StudentProfileDialog(student: s),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  KaliIconButton.action(
                    Icons.edit_outlined,
                    tooltip: 'Editar',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditStudentDialog(student: s),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  KaliIconButton.action(
                    Icons.delete_outline,
                    tooltip: 'Eliminar',
                    color: const Color(0xFFD4685C),
                    onTap: () => _confirmDelete(context),
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

// ─── Patologías ───────────────────────────────────────────────────────────────
class _PatologiasCell extends StatelessWidget {
  final List<String> patologias;
  const _PatologiasCell({required this.patologias});

  @override
  Widget build(BuildContext context) {
    if (patologias.isEmpty) {
      return Text(
        'Ninguna',
        style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.35), size: 13),
      );
    }

    // Mostramos chips en una única fila para no alterar la altura de la tabla.
    // Si hay más de 1, el segundo chip muestra "+N más".
    final first = patologias.first;
    final extra = patologias.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _PatologiaChip(label: first)),
        if (extra > 0) ...[
          const SizedBox(width: 4),
          _PatologiaChip(label: '+$extra', muted: true),
        ],
      ],
    );
  }
}

class _PatologiaChip extends StatelessWidget {
  final String label;
  final bool muted;
  const _PatologiaChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? KaliColors.espresso.withValues(alpha: 0.06)
            : KaliColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KaliColors.espresso.withValues(alpha: muted ? 0.1 : 0.15),
        ),
      ),
      child: Text(
        label,
        style: KaliText.label(
          KaliColors.espresso.withValues(alpha: muted ? 0.45 : 0.75),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Asistencias del mes ──────────────────────────────────────────────────────
class _AttendanceCell extends StatelessWidget {
  final int count;
  const _AttendanceCell({required this.count});

  @override
  Widget build(BuildContext context) {
    final hasAttended = count > 0;
    final color = hasAttended ? const Color(0xFF5C9E6C) : KaliColors.espresso.withValues(alpha: 0.3);
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$count ${count == 1 ? 'clase' : 'clases'}',
          style: KaliText.body(color, weight: FontWeight.w500, size: 13),
        ),
      ],
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
