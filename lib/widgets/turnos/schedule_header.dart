import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:intl/intl.dart';

/// Header del calendario semanal con título, rango de fechas y filtros.
class ScheduleHeader extends StatelessWidget {
  final DateTime currentWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onCreateTurno;
  final VoidCallback onCreateTemplate;

  const ScheduleHeader({
    super.key,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onCreateTurno,
    required this.onCreateTemplate,
  });

  String get _weekRange {
    final endOfWeek = currentWeekStart.add(const Duration(days: 6));
    const formatStr = "dd MMM";
    return '${DateFormat(formatStr, 'es_ES').format(currentWeekStart)} — ${DateFormat(formatStr, 'es_ES').format(endOfWeek)}, ${endOfWeek.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Calendario Semanal',
                      style: KaliText.heading(KaliColors.espresso, size: 40)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 24),
                    // Navigation controls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KaliColors.espresso.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 24),
                            onPressed: onPreviousWeek,
                            color: KaliColors.espresso,
                            tooltip: 'Semana Anterior',
                          ),
                          Container(width: 1, height: 24, color: KaliColors.espresso.withValues(alpha: 0.1)),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 24),
                            onPressed: onNextWeek,
                            color: KaliColors.espresso,
                            tooltip: 'Próxima Semana',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _weekRange,
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
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onCreateTemplate,
                icon: Icon(Icons.note_add_outlined, size: 20, color: KaliColors.espresso.withValues(alpha: 0.7)),
                label: Text(
                  'Nueva Plantilla',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.7), weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onCreateTurno,
                icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                label: Text(
                  'Nuevo Turno',
                  style: KaliText.body(Colors.white, weight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaliColors.espresso,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
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
