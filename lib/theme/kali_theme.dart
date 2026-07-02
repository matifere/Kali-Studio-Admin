import 'package:flutter/material.dart';
import 'kali_colors_extension.dart';

// ─── Paleta de colores ────────────────────────────────────────────────────────
class KaliColors {
  static const Color espresso = Color(0xFF2C1F14);
  static const Color espressoL = Color(0xFF3D2B1A);
  static const Color clay = Color(0xFFC4A882);
  static const Color clayDark = Color(0xFFA08060);
  static const Color sand = Color(0xFFF5F0E8);
  static const Color sand2 = Color(0xFFEDE6D8);
  static const Color sage = Color(0xFF8A9E88);
  static const Color sageLight = Color(0xFFD4DDD3);
  static const Color warmWhite = Color(0xFFFAF7F2);
  static const Color background = Color(0xFFE8E2D8);
}

// ─── Tema global ──────────────────────────────────────────────────────────────
class KaliTheme {
  static ThemeData buildTheme(KaliColorsExtension colors) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.warmWhite,
      colorScheme: ColorScheme.light(
        primary: colors.espresso,
        secondary: colors.clay,
        surface: colors.warmWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.espresso,
        foregroundColor: colors.warmWhite,
        elevation: 0,
        centerTitle: true,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.warmWhite,
        hourMinuteTextColor: colors.espresso,
        hourMinuteColor: colors.background,
        dayPeriodTextColor: colors.espresso,
        dayPeriodColor: colors.background,
        dialHandColor: colors.espresso,
        dialBackgroundColor: colors.background,
        dialTextColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.warmWhite
                : colors.espresso),
        entryModeIconColor: colors.espresso,
        helpTextStyle: TextStyle(color: colors.espresso),
        cancelButtonStyle:
            TextButton.styleFrom(foregroundColor: colors.espresso),
        confirmButtonStyle:
            TextButton.styleFrom(foregroundColor: colors.espresso),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.warmWhite,
        headerBackgroundColor: colors.espresso,
        headerForegroundColor: colors.warmWhite,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.warmWhite;
          return colors.espresso;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.warmWhite;
          return colors.espresso;
        }),
        dayOverlayColor:
            WidgetStateProperty.all(colors.espresso.withValues(alpha: 0.1)),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.warmWhite;
          return colors.espresso;
        }),
        cancelButtonStyle:
            TextButton.styleFrom(foregroundColor: colors.espresso),
        confirmButtonStyle:
            TextButton.styleFrom(foregroundColor: colors.espresso),
      ),
      extensions: [colors],
    );
  }
}
