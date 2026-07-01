import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/cubits/theme/theme_cubit.dart';

class SettingsThemeScreen extends StatelessWidget {
  const SettingsThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema Visual',
            style: KaliText.heading(kaliColors.espresso, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalizá los colores de tu espacio de trabajo.',
            style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          const Wrap(
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
            ],
          ),
        ],
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
    // En un caso real, el ThemeCubit podría guardar el themeId seleccionado actual,
    // o podríamos adivinar si el tema activo es igual a éste. Para simplicidad de UI
    // comparamos el fondo para saber si está (más o menos) activo, o dejamos sin marcar.
    // Una opción robusta: que ThemeCubit exponga el ID.
    // Comparamos colores clave para saber si es el tema activo
    final isActive = activeKaliColors.espresso == themeColors.espresso &&
        activeKaliColors.background == themeColors.background;

    return InkWell(
      onTap: () {
        context.read<ThemeCubit>().changeTheme(themeId);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: activeKaliColors.warmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeKaliColors.espresso : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
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
            Text(
              title,
              style: KaliText.body(activeKaliColors.espresso, weight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Preview de los colores
            Row(
              children: [
                _ColorCircle(color: themeColors.espresso),
                const SizedBox(width: 8),
                _ColorCircle(color: themeColors.clay),
                const SizedBox(width: 8),
                _ColorCircle(color: themeColors.sand),
                const SizedBox(width: 8),
                _ColorCircle(color: themeColors.background),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;

  const _ColorCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 1),
      ),
    );
  }
}
