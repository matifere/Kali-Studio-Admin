import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/turnos/day_column.dart';
import 'package:argrity/widgets/turnos/time_labels_column.dart';

class MobileDaySchedule extends StatefulWidget {
  final DateTime currentWeekStart;
  final List<ClassSession> sessions;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final int startHour;
  final int totalSlots;
  final int slotsPerHour;

  const MobileDaySchedule({
    super.key,
    required this.currentWeekStart,
    required this.sessions,
    required this.selectedTurno,
    required this.onTurnoSelected,
    required this.startHour,
    required this.totalSlots,
    required this.slotsPerHour,
  });

  @override
  State<MobileDaySchedule> createState() => _MobileDayScheduleState();
}

class _MobileDayScheduleState extends State<MobileDaySchedule> {
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
            buildTimeLabelsColumn(
              slotH: slotH,
              startHour: widget.startHour,
              totalSlots: widget.totalSlots,
              slotsPerHour: widget.slotsPerHour,
            ),
            Expanded(
              child: DayColumn(
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
