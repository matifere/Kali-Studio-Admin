import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Header del calendario semanal con título, rango de fechas y filtros.
class ScheduleHeader extends StatelessWidget {
  final String weekRange;

  const ScheduleHeader({
    super.key,
    this.weekRange = 'Octubre 23 — Octubre 29, 2023',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendario Semanal',
            style: KaliText.heading(KaliColors.espresso, size: 40)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            weekRange,
            style: KaliText.body(
              KaliColors.espresso.withValues(alpha: 0.5),
              size: 14,
            ),
          ),
          const SizedBox(height: 20),
          // Filtros
          const Row(
            children: [
              _FilterDropdown(label: 'Todos los Instructores'),
              SizedBox(width: 12),
              _FilterDropdown(label: 'Todas las Salas'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dropdown de filtro ───────────────────────────────────────────────────────
class _FilterDropdown extends StatefulWidget {
  final String label;

  const _FilterDropdown({required this.label});

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
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
              widget.label,
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
