import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Indicador de estado vacío reutilizable.
///
/// Muestra un ícono, un título y un subtítulo centrados.
class KaliEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const KaliEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: KaliColors.espresso.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: KaliText.body(
                KaliColors.espresso.withValues(alpha: 0.5),
                weight: FontWeight.w600,
                size: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: KaliText.body(
                KaliColors.espresso.withValues(alpha: 0.35),
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
