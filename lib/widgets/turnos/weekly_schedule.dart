import 'package:flutter/material.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/turnos/turno_card.dart';
import 'package:intl/intl.dart';

/// Grilla del calendario semanal 7 columnas (Lun–Dom).
///
/// Cada turno se posiciona con [Stack] + [Positioned] según su hora de inicio
/// y duración. Turnos solapados se muestran en carriles side-by-side.
class WeeklySchedule extends StatelessWidget {
  final DateTime currentWeekStart;
  final List<ClassSession> sessions;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;

  const WeeklySchedule({
    super.key,
    required this.currentWeekStart,
    required this.sessions,
    this.selectedTurno,
    required this.onTurnoSelected,
  });

  // Rango horario visible en la grilla.
  int get _startHour => 7;
  int get _endHour => 22;

  int get _totalHours {
    final start = _startHour;
    final end = _endHour;
    return end > start ? end - start : 1;
  }

  // Cada hora = 2 celdas de 30 min.
  static const int _slotsPerHour = 2;
  int get _totalSlots => _totalHours * _slotsPerHour;
  

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En celular la grilla de 7 días no entra: mostramos un solo día con
        // un selector arriba, en vez de obligar a scrollear horizontalmente.
        const double mobileBreakpoint = 640.0;
        if (constraints.maxWidth < mobileBreakpoint) {
          return _MobileDaySchedule(
            currentWeekStart: currentWeekStart,
            sessions: sessions,
            selectedTurno: selectedTurno,
            onTurnoSelected: onTurnoSelected,
            startHour: _startHour,
            totalSlots: _totalSlots,
            slotsPerHour: _slotsPerHour,
          );
        }

        const double minWidth = 680.0;
        final needsScroll = constraints.maxWidth < minWidth;
        final schedule = Column(
          children: [
            _buildDayHeaders(),
            Expanded(child: _buildScheduleBody()),
          ],
        );
        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: minWidth, child: schedule),
          );
        }
        return schedule;
      },
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
      child: Row(
        children: List.generate(7, (i) {
          final dayDate = currentWeekStart.add(Duration(days: i));
          final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
          final dayName = DateFormat('EEE', 'es_ES').format(dayDate).toUpperCase();
          return Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

  // ── Cuerpo del calendario: horas + grilla por día ─────────────────────────
  Widget _buildScheduleBody() {
    final now = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minSlotH = 17.0;
        final double slotH = (constraints.maxHeight / _totalSlots).clamp(minSlotH, double.infinity);
        final double totalH = slotH * _totalSlots;

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeLabels(slotH),
            ...List.generate(7, (dayIdx) {
              final dayDate = currentWeekStart.add(Duration(days: dayIdx));
              final isToday = dayDate.year == now.year &&
                  dayDate.month == now.month &&
                  dayDate.day == now.day;
              return Expanded(
                child: _DayColumn(
                  dayIndex: dayIdx,
                  isToday: isToday,
                  turnos: sessions.where((t) => t.dayIndex == dayIdx).toList(),
                  selectedTurno: selectedTurno,
                  onTurnoSelected: onTurnoSelected,
                  startHour: _startHour,
                  slotHeight: slotH,
                  totalSlots: _totalSlots,
                ),
              );
            }),
          ],
        );

        if (totalH > constraints.maxHeight) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(height: totalH, child: row),
          );
        }
        return SizedBox(height: constraints.maxHeight, child: row);
      },
    );
  }

  // ── Columna lateral de horas ───────────────────────────────────────────────
  Widget _buildTimeLabels(double slotH) {
    return _buildTimeLabelsColumn(
      slotH: slotH,
      startHour: _startHour,
      totalSlots: _totalSlots,
      slotsPerHour: _slotsPerHour,
    );
  }
}

// ── Columna lateral de horas (reutilizable por la vista semanal y la diaria) ──
Widget _buildTimeLabelsColumn({
  required double slotH,
  required int startHour,
  required int totalSlots,
  required int slotsPerHour,
}) {
  return SizedBox(
    width: 60,
    child: Column(
      children: List.generate(totalSlots, (i) {
        final hour = startHour + i ~/ slotsPerHour;
        final isFullHour = i % slotsPerHour == 0;
        return SizedBox(
          height: slotH,
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

// ─── Columna de un día con turnos posicionados ───────────────────────────────
class _DayColumn extends StatelessWidget {
  final int dayIndex;
  final bool isToday;
  final List<ClassSession> turnos;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final int startHour;
  final double slotHeight;
  final int totalSlots;

  const _DayColumn({
    required this.dayIndex,
    required this.isToday,
    required this.turnos,
    required this.selectedTurno,
    required this.onTurnoSelected,
    required this.startHour,
    required this.slotHeight,
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

  // Asigna carriles (colIndex, totalCols) a cada turno para evitar solapamiento visual.
  List<_SessionLayout> _computeLayouts() {
    if (turnos.isEmpty) return [];

    final sorted = [...turnos]..sort((a, b) {
        final aM = a.parsedStartTime.hour * 60 + a.parsedStartTime.minute;
        final bM = b.parsedStartTime.hour * 60 + b.parsedStartTime.minute;
        return aM.compareTo(bM);
      });

    // colEnd[c] = minuto de fin del último turno colocado en el carril c
    final List<int> colEnd = [];
    final Map<String, int> colOf = {};

    for (final t in sorted) {
      final tStart = t.parsedStartTime.hour * 60 + t.parsedStartTime.minute;
      final tEnd = t.parsedEndTime.hour * 60 + t.parsedEndTime.minute;

      int placed = -1;
      for (int c = 0; c < colEnd.length; c++) {
        if (colEnd[c] <= tStart) {
          placed = c;
          colEnd[c] = tEnd;
          break;
        }
      }
      if (placed == -1) {
        placed = colEnd.length;
        colEnd.add(tEnd);
      }
      colOf[t.id] = placed;
    }

    // totalCols de cada turno = carril máximo entre todos los que se solapan + 1
    return sorted.map((t) {
      final tStart = t.parsedStartTime.hour * 60 + t.parsedStartTime.minute;
      final tEnd = t.parsedEndTime.hour * 60 + t.parsedEndTime.minute;
      int maxCol = colOf[t.id]!;
      for (final o in sorted) {
        if (o.id == t.id) continue;
        final oStart = o.parsedStartTime.hour * 60 + o.parsedStartTime.minute;
        final oEnd = o.parsedEndTime.hour * 60 + o.parsedEndTime.minute;
        if (tStart < oEnd && oStart < tEnd) {
          final oCol = colOf[o.id]!;
          if (oCol > maxCol) maxCol = oCol;
        }
      }
      return _SessionLayout(t, colOf[t.id]!, maxCol + 1);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final layouts = _computeLayouts();

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.hardEdge,
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
              // Tarjetas de turnos posicionadas con solapamiento resuelto
              ...layouts.map((layout) {
                final t = layout.turno;
                final cardHeight = _heightForTurno(t) - 4;
                if (cardHeight < 4) return const SizedBox.shrink();
                final isSelected = selectedTurno?.id == t.id;

                final slotW = (colWidth - 8) / layout.totalCols;
                final cardLeft = 4.0 + layout.colIndex * slotW;
                final cardWidth = slotW - 2;

                return Positioned(
                  top: _topForTurno(t),
                  left: cardLeft,
                  width: cardWidth,
                  height: cardHeight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: isSelected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: KaliColors.espresso.withValues(alpha: 0.15),
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
          );
        },
      ),
    );
  }
}

class _SessionLayout {
  final ClassSession turno;
  final int colIndex;
  final int totalCols;
  const _SessionLayout(this.turno, this.colIndex, this.totalCols);
}

// ─── Vista diaria para celular ────────────────────────────────────────────────
//
// Selector de días arriba + una sola columna de turnos a ancho completo, para
// evitar el scroll horizontal de la grilla semanal en pantallas angostas.
class _MobileDaySchedule extends StatefulWidget {
  final DateTime currentWeekStart;
  final List<ClassSession> sessions;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final int startHour;
  final int totalSlots;
  final int slotsPerHour;

  const _MobileDaySchedule({
    required this.currentWeekStart,
    required this.sessions,
    required this.selectedTurno,
    required this.onTurnoSelected,
    required this.startHour,
    required this.totalSlots,
    required this.slotsPerHour,
  });

  @override
  State<_MobileDaySchedule> createState() => _MobileDayScheduleState();
}

class _MobileDayScheduleState extends State<_MobileDaySchedule> {
  // Día seleccionado dentro de la semana (0 = lunes … 6 = domingo).
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _todayIndexOrZero();
  }

  int _todayIndexOrZero() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = widget.currentWeekStart.add(Duration(days: i));
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDayPicker(),
        Expanded(child: _buildDayBody()),
      ],
    );
  }

  // ── Selector de días (Lun … Dom) ───────────────────────────────────────────
  Widget _buildDayPicker() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: KaliColors.espresso.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final dayDate = widget.currentWeekStart.add(Duration(days: i));
          final isToday = dayDate.year == now.year &&
              dayDate.month == now.month &&
              dayDate.day == now.day;
          final isSelected = i == _selectedDay;
          final dayName =
              DateFormat('EEE', 'es_ES').format(dayDate).toUpperCase();
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedDay = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: KaliText.label(
                      isSelected
                          ? KaliColors.espresso
                          : KaliColors.espresso.withValues(alpha: 0.45),
                    ).copyWith(fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? KaliColors.espresso
                          : (isToday
                              ? KaliColors.sand
                              : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${dayDate.day}',
                      style: KaliText.body(
                        isSelected
                            ? KaliColors.warmWhite
                            : KaliColors.espresso,
                        weight:
                            isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                        size: 14,
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

  // ── Cuerpo: horas + columna del día seleccionado ───────────────────────────
  Widget _buildDayBody() {
    final now = DateTime.now();
    final dayDate = widget.currentWeekStart.add(Duration(days: _selectedDay));
    final isToday = dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
    final dayTurnos =
        widget.sessions.where((t) => t.dayIndex == _selectedDay).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Slots más altos que en desktop para que el toque sea cómodo.
        const double minSlotH = 26.0;
        final double slotH = (constraints.maxHeight / widget.totalSlots)
            .clamp(minSlotH, double.infinity);
        final double totalH = slotH * widget.totalSlots;

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeLabelsColumn(
              slotH: slotH,
              startHour: widget.startHour,
              totalSlots: widget.totalSlots,
              slotsPerHour: widget.slotsPerHour,
            ),
            Expanded(
              child: _DayColumn(
                dayIndex: _selectedDay,
                isToday: isToday,
                turnos: dayTurnos,
                selectedTurno: widget.selectedTurno,
                onTurnoSelected: widget.onTurnoSelected,
                startHour: widget.startHour,
                slotHeight: slotH,
                totalSlots: widget.totalSlots,
              ),
            ),
          ],
        );

        final body = totalH > constraints.maxHeight
            ? SingleChildScrollView(
                child: SizedBox(height: totalH, child: content),
              )
            : SizedBox(height: constraints.maxHeight, child: content);

        if (dayTurnos.isEmpty) {
          return Stack(
            children: [
              body,
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'No hay turnos este día',
                      style: KaliText.body(
                        KaliColors.espresso.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return body;
      },
    );
  }
}
