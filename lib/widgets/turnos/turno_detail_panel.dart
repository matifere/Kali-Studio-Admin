import 'package:flutter/material.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';

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
      width: 300,
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
          const Spacer(),
          _buildActions(),
          const SizedBox(height: 20),
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
              Text(
                turno.occupancyText,
                style: KaliText.label(
                  KaliColors.espresso.withValues(alpha: 0.7),
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

  // ── Botones de acción ──────────────────────────────────────────────────────
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.move_to_inbox_outlined,
            label: 'Reprogramar Clase',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Cancelar Sesión',
            onTap: () {},
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
