import 'package:flutter/material.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Barra inferior del calendario con leyenda de tipos y estadísticas.
class ScheduleBottomBar extends StatelessWidget {
  final List<ClassSession> sessions;

  const ScheduleBottomBar({super.key, required this.sessions});

  int get _totalClasses => sessions.length;
  int get _totalCapacity => sessions.fold<int>(0, (sum, s) => sum + s.capacity);
  int get _totalEnrolled => sessions.fold<int>(0, (sum, s) => sum + s.enrolled);
  String get _capacityPercent => _totalCapacity > 0
      ? '${((_totalEnrolled / _totalCapacity) * 100).round()}%'
      : '0%';

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 640;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 28, vertical: isSmall ? 10 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: kaliColors.espresso.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),

          // Stats
          _StatChip(
              label: 'CAPACIDAD SEMANAL',
              value: _capacityPercent,
              compact: isSmall),
          SizedBox(width: isSmall ? 20 : 32),
          _StatChip(label: 'TOTAL CLASES', value: '$_totalClasses', compact: isSmall),
        ],
      ),
    );
  }
}

// ─── Dot de leyenda ───────────────────────────────────────────────────────────
/*class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: KaliText.body(kaliColors.espresso, size: 12)),
      ],
    );
  }
}*/

// ─── Chip de estadística ──────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _StatChip({required this.label, required this.value, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: KaliText.label(
            kaliColors.espresso.withValues(alpha: 0.45),
          ).copyWith(fontSize: compact ? 10 : null),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          value,
          style: KaliText.body(
            kaliColors.espresso,
            weight: FontWeight.w700,
            size: compact ? 16 : 22,
          ),
        ),
      ],
    );
  }
}
