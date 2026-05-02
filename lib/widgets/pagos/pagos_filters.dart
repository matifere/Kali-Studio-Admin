import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/pagos/create_plan_dialog.dart';

/// Barra de filtros y acciones de la sección de pagos.
class PagosFilters extends StatelessWidget {
  const PagosFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rango de fechas
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RANGO DE FECHAS',
              style: KaliText.label(
                KaliColors.espresso.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            const _DateRangeChip(),
          ],
        ),
        const SizedBox(width: 24),
        // Estado
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTADO',
              style: KaliText.label(
                KaliColors.espresso.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            const _StatusDropdown(),
          ],
        ),
        const Spacer(),
        // Botones de acción
        const _OutlinedActionBtn(
          icon: Icons.download_rounded,
          label: 'Exportar Reporte',
        ),
        const SizedBox(width: 12),
        _FilledActionBtn(
          icon: Icons.add_card_rounded,
          label: 'Crear Plan',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const CreatePlanDialog(),
            );
          },
        ),
        const SizedBox(width: 12),
        const _FilledActionBtn(
          icon: Icons.add,
          label: 'Registrar Pago',
        ),
      ],
    );
  }
}

// ─── Chip de rango de fechas ──────────────────────────────────────────────────
class _DateRangeChip extends StatefulWidget {
  const _DateRangeChip();

  @override
  State<_DateRangeChip> createState() => _DateRangeChipState();
}

class _DateRangeChipState extends State<_DateRangeChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? KaliColors.sand : KaliColors.espresso,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mar 01 - Mar 31, 2024',
              style: KaliText.body(
                _hovered ? KaliColors.espresso : KaliColors.warmWhite,
                weight: FontWeight.w500,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: _hovered ? KaliColors.espresso : KaliColors.warmWhite,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown de estado ───────────────────────────────────────────────────────
class _StatusDropdown extends StatefulWidget {
  const _StatusDropdown();

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? KaliColors.sand : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: KaliColors.espresso.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Todos los Estados',
              style: KaliText.body(
                KaliColors.espresso,
                weight: FontWeight.w500,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de acción con borde ────────────────────────────────────────────────
class _OutlinedActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;

  const _OutlinedActionBtn({required this.icon, required this.label});

  @override
  State<_OutlinedActionBtn> createState() => _OutlinedActionBtnState();
}

class _OutlinedActionBtnState extends State<_OutlinedActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.sand : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: KaliColors.espresso.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: KaliColors.espresso),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: KaliText.body(
                  KaliColors.espresso,
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

// ─── Botón de acción relleno ──────────────────────────────────────────────────
class _FilledActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FilledActionBtn({required this.icon, required this.label, this.onTap});

  @override
  State<_FilledActionBtn> createState() => _FilledActionBtnState();
}

class _FilledActionBtnState extends State<_FilledActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.espressoL : KaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: KaliColors.espresso.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: KaliColors.warmWhite),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: KaliText.body(
                  KaliColors.warmWhite,
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
