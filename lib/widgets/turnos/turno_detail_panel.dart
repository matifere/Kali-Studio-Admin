import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/turnos/edit_turno_dialog.dart';
import 'package:kali_studio/widgets/turnos/assign_student_dialog.dart';
import 'package:kali_studio/widgets/common/avatar_provider.dart';

/// Panel lateral con los detalles de un turno seleccionado.
class TurnoDetailPanel extends StatelessWidget {
  final ClassSession turno;
  final VoidCallback onClose;

  const TurnoDetailPanel({
    super.key,
    required this.turno,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          _buildSlotInfo(),
          if (turno.description != null && turno.description!.isNotEmpty) 
            _buildDescription(),
          const SizedBox(height: 16),
          Expanded(child: _buildEnrolledStudents(context)),
          _buildActions(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Detalles de Clase',
            style: KaliText.body(
              KaliColors.espresso,
              weight: FontWeight.w700,
              size: 16,
            ),
          ),
          KaliIconButton(
            Icons.close,
            tooltip: 'Cerrar',
            onTap: onClose,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  // ── Info del slot ──────────────────────────────────────────────────────────
  Widget _buildSlotInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TURNO SELECCIONADO',
                style: KaliText.label(
                  KaliColors.espresso.withValues(alpha: 0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: turno.isFull ? const Color(0xFFD4685C).withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  turno.occupancyText,
                  style: KaliText.label(
                    turno.isFull ? const Color(0xFFD4685C) : KaliColors.espresso.withValues(alpha: 0.7),
                  ).copyWith(fontWeight: turno.isFull ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            turno.name,
            style: KaliText.body(
              KaliColors.espresso,
              weight: FontWeight.w700,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${turno.startTimeFormatted} - ${turno.endTimeFormatted}',
            style: KaliText.body(
              KaliColors.espresso.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            turno.instructorName ?? 'Sin instructor',
            style: KaliText.body(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPCIÓN',
            style: KaliText.label(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            turno.description!,
            style: KaliText.body(
              KaliColors.espresso.withValues(alpha: 0.7),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Alumnos inscriptos ──────────────────────────────────────────────────────
  Widget _buildEnrolledStudents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALUMNOS INSCRIPTOS',
                style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5)),
              ),
              if (!turno.isFull)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<TurnosBloc>(),
                        child: AssignStudentDialog(session: turno),
                      ),
                    );
                  },
                  child: Text(
                    '+ Inscribir',
                    style: KaliText.label(KaliColors.espresso).copyWith(
                      color: KaliColors.espresso,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: turno.enrolledStudents.isEmpty
              ? Center(
                  child: Text(
                    'No hay alumnos inscriptos.',
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: turno.enrolledStudents.length,
                  itemBuilder: (context, index) {
                    final student = turno.enrolledStudents[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: KaliColors.clay,
                        backgroundImage: AvatarProvider.fromUrl(student.avatarUrl),
                        child: student.avatarUrl == null 
                          ? Text(student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 10))
                          : null,
                      ),
                      title: Text(
                        student.studentName,
                        style: KaliText.body(KaliColors.espresso, weight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.close, size: 16, color: KaliColors.espresso.withValues(alpha: 0.5)),
                        onPressed: () {
                          context.read<TurnosBloc>().add(TurnoStudentRemoved(student.id));
                        },
                        tooltip: 'Desinscribir',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Botones de acción ──────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Editar / Reprogramar',
            onTap: () {
              final bloc = context.read<TurnosBloc>();
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: EditTurnoDialog(turno: turno),
                ),
              );
              onClose(); // Cerrar panel tras abrir
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Cancelar Sesión',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancelar sesión'),
                  content: Text('¿Seguro que deseas cancelar la clase de ${turno.name}? Esta acción eliminará el turno completamente.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Volver')),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancelar Sesión')
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                if (context.mounted) {
                  context.read<TurnosBloc>().add(TurnoDeleted(turno.id));
                }
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

// ─── Botón de acción del panel ────────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFFD4685C)
        : KaliColors.espresso;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDestructive
                    ? const Color(0xFFFDF0EE)
                    : KaliColors.sand)
                : Colors.transparent,
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: KaliText.body(
                  color,
                  weight: FontWeight.w600,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
