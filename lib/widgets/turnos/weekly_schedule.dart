import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/turnos/turno_card.dart';
import 'package:intl/intl.dart';

/// Grilla del calendario semanal.
///
/// Usa [StaggeredGrid] del paquete `flutter_staggered_grid_view`
/// para posicionar las tarjetas de turnos en una grilla de 7 columnas
/// (Lun–Dom) donde cada turno ocupa un número variable de celdas
/// verticales según su duración.
class WeeklySchedule extends StatelessWidget {
  final DateTime currentWeekStart;
  final List<ClassSession> sessions;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final bool isCompactMode;

  const WeeklySchedule({
    super.key,
    required this.currentWeekStart,
    required this.sessions,
    this.selectedTurno,
    required this.onTurnoSelected,
    required this.isCompactMode,
  });

  // Rango horario visible en la grilla.
  int get _startHour {
    if (!isCompactMode || sessions.isEmpty) return 7;
    int minHour = 24;
    for (var s in sessions) {
      if (s.parsedStartTime.hour < minHour) {
        minHour = s.parsedStartTime.hour;
      }
    }
    return minHour;
  }

  int get _endHour {
    if (!isCompactMode || sessions.isEmpty) return 22;
    int maxHour = 0;
    for (var s in sessions) {
      int endH = s.parsedEndTime.hour;
      if (s.parsedEndTime.minute > 0) endH += 1;
      if (endH > maxHour) {
        maxHour = endH;
      }
    }
    return maxHour;
  }

  int get _totalHours {
    final start = _startHour;
    final end = _endHour;
    return end > start ? end - start : 1;
  }

  // Cada hora = 2 celdas de 30 min.
  static const int _slotsPerHour = 2;
  int get _totalSlots => _totalHours * _slotsPerHour;
  
  double get _slotHeight => isCompactMode ? 24.0 : 48.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDayHeaders(),
        Expanded(child: _buildScheduleBody()),
      ],
    );
  }

  // ── Headers de días ────────────────────────────────────────────────────────
  Widget _buildDayHeaders() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(60, 16, 0, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: KaliColors.espresso.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: StaggeredGrid.count(
        crossAxisCount: 7,
        children: List.generate(7, (i) {
          final dayDate = currentWeekStart.add(Duration(days: i));
          final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
          final dayName = DateFormat('EEE', 'es_ES').format(dayDate).toUpperCase();
          return StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: Center(
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: KaliText.label(
                      isToday
                          ? KaliColors.espresso
                          : KaliColors.espresso.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          isToday ? KaliColors.espresso : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${dayDate.day}',
                      style: KaliText.body(
                        isToday ? KaliColors.warmWhite : KaliColors.espresso,
                        weight: isToday ? FontWeight.w700 : FontWeight.w400,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Cuerpo del calendario: horas + grilla staggered por día ────────────────
  Widget _buildScheduleBody() {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: _totalSlots * _slotHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna de horas
            _buildTimeLabels(),
            // 7 columnas de días
            ...List.generate(7, (dayIdx) {
              final dayDate = currentWeekStart.add(Duration(days: dayIdx));
              final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
              return Expanded(
                child: _DayColumn(
                  dayIndex: dayIdx,
                  isToday: isToday,
                  turnos: sessions.where((t) => t.dayIndex == dayIdx).toList(),
                  selectedTurno: selectedTurno,
                  onTurnoSelected: onTurnoSelected,
                  startHour: _startHour,
                  slotHeight: _slotHeight,
                  isCompactMode: isCompactMode,
                  totalSlots: _totalSlots,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Columna lateral de horas ───────────────────────────────────────────────
  Widget _buildTimeLabels() {
    return SizedBox(
      width: 60,
      child: Column(
        children: List.generate(_totalSlots, (i) {
          final hour = _startHour + i ~/ _slotsPerHour;
          final isFullHour = i % _slotsPerHour == 0;
          return SizedBox(
            height: _slotHeight,
            child: isFullHour
                ? Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: KaliText.label(
                          KaliColors.espresso.withValues(alpha: 0.3),
                        ).copyWith(fontSize: isCompactMode ? 10 : null),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ),
    );
  }
}

// ─── Columna de un día con turnos posicionados ───────────────────────────────
class _DayColumn extends StatelessWidget {
  final int dayIndex;
  final bool isToday;
  final List<ClassSession> turnos;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final int startHour;
  final double slotHeight;
  final bool isCompactMode;
  final int totalSlots;

  const _DayColumn({
    required this.dayIndex,
    required this.isToday,
    required this.turnos,
    required this.selectedTurno,
    required this.onTurnoSelected,
    required this.startHour,
    required this.slotHeight,
    required this.isCompactMode,
    required this.totalSlots,
  });

  double _topForTurno(ClassSession t) {
    final start = t.parsedStartTime;
    final minutesFromStart = (start.hour - startHour) * 60 + start.minute;
    return (minutesFromStart / 30) * slotHeight;
  }

  double _heightForTurno(ClassSession t) {
    final start = t.parsedStartTime;
    final end = t.parsedEndTime;
    final durationMinutes = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    return (durationMinutes / 30) * slotHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? KaliColors.sand.withValues(alpha: 0.35)
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: KaliColors.espresso.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Stack(
        children: [
          // Líneas horizontales de grilla
          ...List.generate(
            totalSlots,
            (i) => Positioned(
              top: i * slotHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: i % 2 == 0
                    ? KaliColors.espresso.withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
            ),
          ),
          // Tarjetas de turnos posicionadas
          ...turnos.map((t) {
            final isSelected = selectedTurno?.id == t.id;
            return Positioned(
              top: _topForTurno(t),
              left: 4,
              right: 4,
              height: _heightForTurno(t) - 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: KaliColors.espresso
                                .withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                child: TurnoCard(
                  turno: t,
                  isCompactMode: isCompactMode,
                  onTap: () => onTurnoSelected(t),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
