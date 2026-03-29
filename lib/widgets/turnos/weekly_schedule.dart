import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kali_studio/data/mock_turnos.dart';
import 'package:kali_studio/models/turno.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/turnos/turno_card.dart';

/// Grilla del calendario semanal.
///
/// Usa [StaggeredGrid] del paquete `flutter_staggered_grid_view`
/// para posicionar las tarjetas de turnos en una grilla de 5 columnas
/// (Lun–Vie) donde cada turno ocupa un número variable de celdas
/// verticales según su duración.
class WeeklySchedule extends StatelessWidget {
  final List<Turno> turnos;
  final int todayIndex;
  final Turno? selectedTurno;
  final ValueChanged<Turno> onTurnoSelected;

  const WeeklySchedule({
    super.key,
    this.turnos = kMockTurnos,
    this.todayIndex = kTodayIndex,
    this.selectedTurno,
    required this.onTurnoSelected,
  });

  // Rango horario visible en la grilla.
  static const int _startHour = 7;
  static const int _endHour = 22;
  static const int _totalHours = _endHour - _startHour;
  // Cada hora = 2 celdas de 30 min.
  static const int _slotsPerHour = 2;
  static const int _totalSlots = _totalHours * _slotsPerHour;
  static const double _slotHeight = 48.0;

  /// Cuántas celdas de grilla (slots de 30 min) ocupa un turno.
  int _cellCountForTurno(Turno t) =>
      (t.durationMinutes / 30).ceil().clamp(1, _totalSlots);

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
        crossAxisCount: 5,
        children: List.generate(5, (i) {
          final isToday = i == todayIndex;
          return StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: Center(
              child: Column(
                children: [
                  Text(
                    kWeekDayLabels[i],
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
                      '${kWeekDayNumbers[i]}',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: _totalSlots * _slotHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna de horas
            _buildTimeLabels(),
            // 5 columnas de días usando StaggeredGrid dentro de cada Stack
            ...List.generate(5, (dayIdx) {
              return Expanded(
                child: _DayColumn(
                  dayIndex: dayIdx,
                  isToday: dayIdx == todayIndex,
                  turnos:
                      turnos.where((t) => t.dayIndex == dayIdx).toList(),
                  selectedTurno: selectedTurno,
                  onTurnoSelected: onTurnoSelected,
                  startHour: _startHour,
                  slotHeight: _slotHeight,
                  cellCountForTurno: _cellCountForTurno,
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
                        ),
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
  final List<Turno> turnos;
  final Turno? selectedTurno;
  final ValueChanged<Turno> onTurnoSelected;
  final int startHour;
  final double slotHeight;
  final int Function(Turno) cellCountForTurno;

  const _DayColumn({
    required this.dayIndex,
    required this.isToday,
    required this.turnos,
    required this.selectedTurno,
    required this.onTurnoSelected,
    required this.startHour,
    required this.slotHeight,
    required this.cellCountForTurno,
  });

  double _topForTurno(Turno t) {
    final minutesFromStart = (t.startHour - startHour) * 60 + t.startMinute;
    return (minutesFromStart / 30) * slotHeight;
  }

  double _heightForTurno(Turno t) {
    return (t.durationMinutes / 30) * slotHeight;
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
            WeeklySchedule._totalSlots,
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
            final isSelected = selectedTurno == t;
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
