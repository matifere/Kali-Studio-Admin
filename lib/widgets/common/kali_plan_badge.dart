import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Badge que muestra el plan del alumno.
///
/// Detecta automáticamente si el plan es premium para resaltar el fondo.
class KaliPlanBadge extends StatelessWidget {
  final String plan;

  const KaliPlanBadge({super.key, required this.plan});

  bool get _isPremium {
    final upper = plan.toUpperCase();
    return upper.contains('PREMIUM') || upper.contains('ANUAL');
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _isPremium ? const Color(0xFFF5D9B8) : kaliColors.sand2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plan,
        style: KaliText.label(
          kaliColors.espresso.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
