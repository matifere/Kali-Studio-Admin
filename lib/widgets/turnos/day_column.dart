import 'package:flutter/material.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/turnos/turno_card.dart';

class DayColumn extends StatelessWidget {
  final int dayIndex;
  final bool isToday;
  final List<ClassSession> turnos;
  final ClassSession? selectedTurno;
  final ValueChanged<ClassSession> onTurnoSelected;
  final int startHour;
  final double slotHeight;
  final int totalSlots;

  const DayColumn({
    super.key,
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
