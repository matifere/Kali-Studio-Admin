import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

Widget buildTimeLabelsColumn({
  required double slotH,
  required int startHour,
  required int totalSlots,
  required int slotsPerHour,
  required KaliColorsExtension kaliColors,
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
                        kaliColors.espresso.withValues(alpha: 0.3),
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
