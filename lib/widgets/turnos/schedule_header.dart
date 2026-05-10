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
  final bool isCompactMode;
  final ValueChanged<bool> onCompactModeChanged;
  final String? selectedInstructor;
  final String? selectedRoom;
  final List<String> availableInstructors;
  final List<String> availableRooms;
  final void Function(String? instructor, String? room) onFilterChanged;

  const ScheduleHeader({
    super.key,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onCreateTurno,
    required this.onCreateTemplate,
    required this.isCompactMode,
    required this.onCompactModeChanged,
    required this.selectedInstructor,
    required this.selectedRoom,
    required this.availableInstructors,
    required this.availableRooms,
    required this.onFilterChanged,
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
                        border: Border.all(
                            color: KaliColors.espresso.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded,
                                size: 24),
                            onPressed: onPreviousWeek,
                            color: KaliColors.espresso,
                            tooltip: 'Semana Anterior',
                          ),
                          Container(
                              width: 1,
                              height: 24,
                              color:
                                  KaliColors.espresso.withValues(alpha: 0.1)),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded,
                                size: 24),
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
                Row(
                  children: [
                    _FilterDropdown(
                      label: selectedInstructor ?? 'Todos los Instructores',
                      options: ['Todos los Instructores', ...availableInstructors],
                      selectedValue: selectedInstructor ?? 'Todos los Instructores',
                      onChanged: (val) {
                        onFilterChanged(
                          val == 'Todos los Instructores' ? null : val,
                          selectedRoom,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _FilterDropdown(
                      label: selectedRoom ?? 'Todas las Salas',
                      options: ['Todas las Salas', ...availableRooms],
                      selectedValue: selectedRoom ?? 'Todas las Salas',
                      onChanged: (val) {
                        onFilterChanged(
                          selectedInstructor,
                          val == 'Todas las Salas' ? null : val,
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    Text('Modo Compacto', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
                    const SizedBox(width: 8),
                    Switch(
                      value: isCompactMode,
                      onChanged: onCompactModeChanged,
                      activeColor: KaliColors.warmWhite,
                      activeTrackColor: KaliColors.espresso,
                      inactiveThumbColor: KaliColors.espresso.withValues(alpha: 0.4),
                      inactiveTrackColor: KaliColors.sand,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onCreateTemplate,
                icon: Icon(Icons.settings_outlined,
                    size: 20,
                    color: KaliColors.espresso.withValues(alpha: 0.7)),
                label: Text(
                  'Administrar Plantillas',
                  style: KaliText.body(
                      KaliColors.espresso.withValues(alpha: 0.7),
                      weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                      color: KaliColors.espresso.withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onCreateTurno,
                icon: const Icon(Icons.add_rounded,
                    size: 20, color: Colors.white),
                label: Text(
                  'Nuevo Turno',
                  style: KaliText.body(Colors.white, weight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaliColors.espresso,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      onSelected: widget.onChanged,
      itemBuilder: (context) => widget.options.map((option) {
        final isSelected = option == widget.selectedValue;
        return PopupMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: KaliText.body(
              isSelected ? KaliColors.espresso : KaliColors.espresso.withValues(alpha: 0.7),
              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
      child: MouseRegion(
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
      ),
    );
  }
}
