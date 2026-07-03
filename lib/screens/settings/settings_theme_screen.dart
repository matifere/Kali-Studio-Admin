import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/cubits/theme/theme_cubit.dart';

class SettingsThemeScreen extends StatelessWidget {
  const SettingsThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 48.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema Visual',
            style: kaliColors.heading(kaliColors.espresso, size: 36),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalizá los colores de tu espacio de trabajo.',
            style: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _ThemeCard(
                themeId: 'default',
                title: 'Café (Default)',
                themeColors: KaliColorsExtension.defaultTheme,
              ),
              _ThemeCard(
                themeId: 'dark',
                title: 'Oscuro',
                themeColors: KaliColorsExtension.darkTheme,
              ),
              _ThemeCard(
                themeId: 'ocean',
                title: 'Océano',
                themeColors: KaliColorsExtension.oceanTheme,
              ),
              _ThemeCard(
                themeId: 'nature',
                title: 'Bosque',
                themeColors: KaliColorsExtension.natureTheme,
              ),
              _ThemeCard(
                themeId: 'magenta',
                title: 'Magenta',
                themeColors: KaliColorsExtension.magentaTheme,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String themeId;
  final String title;
  final KaliColorsExtension themeColors;

  const _ThemeCard({
    required this.themeId,
    required this.title,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final activeKaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final isActive = activeKaliColors.espresso == themeColors.espresso &&
        activeKaliColors.background == themeColors.background;

    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final double cardWidth = isSmall ? double.infinity : 380;

    return InkWell(
      onTap: () async {
        if (isActive) return;
        await context.read<ThemeCubit>().changeTheme(themeId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tema actualizado exitosamente.'),
              backgroundColor: themeColors.espresso,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeColors.warmWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? themeColors.espresso : themeColors.espresso.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: themeColors.espresso.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: themeColors.heading(themeColors.espresso, size: 24).copyWith(fontWeight: FontWeight.bold),
                ),
                if (isActive)
                  Icon(Icons.check_circle_rounded, color: themeColors.espresso, size: 28),
              ],
            ),
            const SizedBox(height: 24),

            // Typography Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Aa',
                  style: themeColors.display(themeColors.espresso, size: 64).copyWith(height: 1.0),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Headline', style: themeColors.heading(themeColors.espresso, size: 16)),
                    Text('Body text example', style: themeColors.body(themeColors.espresso.withValues(alpha: 0.7))),
                    Text('Label', style: themeColors.label(themeColors.espresso.withValues(alpha: 0.5))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Color Palette
            Text('Color Palette', style: themeColors.label(themeColors.espresso.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Row(
              children: [
                _ColorSwatch(color: themeColors.espresso, name: 'Primary'),
                const SizedBox(width: 8),
                _ColorSwatch(color: themeColors.clay, name: 'Secondary'),
                const SizedBox(width: 8),
                _ColorSwatch(color: themeColors.sand, name: 'Surface'),
                const SizedBox(width: 8),
                _ColorSwatch(color: themeColors.background, name: 'Bg'),
              ],
            ),
            const SizedBox(height: 32),

            // UI Elements Preview
            Text('UI Elements', style: themeColors.label(themeColors.espresso.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Row(
              children: [
                // Primary Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeColors.espresso,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Primary', style: themeColors.body(themeColors.getContrastColor(themeColors.espresso), weight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                // Outlined Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: themeColors.espresso.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Outlined', style: themeColors.body(themeColors.espresso, weight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fake Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: themeColors.sand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: themeColors.espresso.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text('Search...', style: themeColors.body(themeColors.espresso.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String name;

  const _ColorSwatch({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
