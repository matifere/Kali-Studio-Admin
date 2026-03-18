import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Paleta de colores ────────────────────────────────────────────────────────
class KaliColors {
  static const Color espresso   = Color(0xFF2C1F14);
  static const Color espressoL  = Color(0xFF3D2B1A);
  static const Color clay       = Color(0xFFC4A882);
  static const Color clayDark   = Color(0xFFA08060);
  static const Color sand       = Color(0xFFF5F0E8);
  static const Color sand2      = Color(0xFFEDE6D8);
  static const Color sage       = Color(0xFF8A9E88);
  static const Color sageLight  = Color(0xFFD4DDD3);
  static const Color warmWhite  = Color(0xFFFAF7F2);
  static const Color background = Color(0xFFE8E2D8);
}

// ─── TextStyles ───────────────────────────────────────────────────────────────
class KaliText {
  static TextStyle display(Color color) => GoogleFonts.cormorantGaramond(
    fontSize: 36, fontWeight: FontWeight.w300,
    color: color, fontStyle: FontStyle.italic,
  );

  static TextStyle heading(Color color, {double size = 24}) =>
    GoogleFonts.cormorantGaramond(
      fontSize: size, fontWeight: FontWeight.w300, color: color,
    );

  static TextStyle headingItalic(Color color, {double size = 26}) =>
    GoogleFonts.cormorantGaramond(
      fontSize: size, fontWeight: FontWeight.w300,
      color: color, fontStyle: FontStyle.italic,
    );

  static TextStyle body(Color color, {double size = 13, FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label(Color color) => GoogleFonts.dmSans(
    fontSize: 9, fontWeight: FontWeight.w500,
    letterSpacing: 1.4, color: color,
  );

  static TextStyle caption(Color color) => GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w300, color: color,
  );
}

// ─── Tema global ──────────────────────────────────────────────────────────────
class KaliTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: KaliColors.warmWhite,
    colorScheme: const ColorScheme.light(
      primary: KaliColors.espresso,
      secondary: KaliColors.clay,
      surface: KaliColors.warmWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KaliColors.espresso,
      foregroundColor: KaliColors.warmWhite,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
