import 'kali_typography.dart';
import 'package:flutter/material.dart';

class KaliColorsExtension extends ThemeExtension<KaliColorsExtension> {
  final KaliTypography typography;
  final Color espresso;
  final Color espressoL;
  final Color clay;
  final Color clayDark;
  final Color sand;
  final Color sand2;
  final Color sage;
  final Color sageLight;
  final Color warmWhite;
  final Color background;

  const KaliColorsExtension({
    required this.typography,
    required this.espresso,
    required this.espressoL,
    required this.clay,
    required this.clayDark,
    required this.sand,
    required this.sand2,
    required this.sage,
    required this.sageLight,
    required this.warmWhite,
    required this.background,
  });

  // ─── Variantes predefinidas ───────────────────────────────────────────────

  static final KaliColorsExtension defaultTheme = KaliColorsExtension(
    espresso: Color(0xFF2C1F14),
    espressoL: Color(0xFF3D2B1A),
    clay: Color(0xFFC4A882),
    clayDark: Color(0xFFA08060),
    sand: Color(0xFFF5F0E8),
    sand2: Color(0xFFEDE6D8),
    sage: Color(0xFF8A9E88),
    sageLight: Color(0xFFD4DDD3),
    warmWhite: Color(0xFFFAF7F2),
    background: Color(0xFFE8E2D8),
    typography: KaliTypography.defaultTypography,
  );

  static final KaliColorsExtension darkTheme = KaliColorsExtension(
    espresso: Color(0xFFF5F0E8),
    espressoL: Color(0xFF37474F),
    clay: Color(0xFFC4A882), // Accent keeping brand identity
    clayDark: Color(0xFFA08060),
    sand: Color(0xFF2C2C2C),
    sand2: Color(0xFF1A1A1A),
    sage: Color(0xFF455A64),
    sageLight: Color(0xFF37474F),
    warmWhite: Color(0xFF121212),
    background: Color(0xFF000000),
    typography: KaliTypography.darkTypography,
  );

  static final KaliColorsExtension oceanTheme = KaliColorsExtension(
    espresso: Color(0xFF0D47A1),
    espressoL: Color(0xFF1565C0),
    clay: Color(0xFF42A5F5),
    clayDark: Color(0xFF1E88E5),
    sand: Color(0xFFE3F2FD),
    sand2: Color(0xFFBBDEFB),
    sage: Color(0xFF26A69A),
    sageLight: Color(0xFF80CBC4),
    warmWhite: Color(0xFFFFFFFF),
    background: Color(0xFFF1F5F9),
    typography: KaliTypography.oceanTypography,
  );

  static final KaliColorsExtension natureTheme = KaliColorsExtension(
    espresso: Color(0xFF1B3B2B), // Deep Forest
    espressoL: Color(0xFF2E5945),
    clay: Color(0xFF83B594),     // Mint/Sage
    clayDark: Color(0xFF5E8E6F),
    sand: Color(0xFFE6EFEB),     // Pale Mint Surface
    sand2: Color(0xFFD6E3DD),
    sage: Color(0xFF88A66D),
    sageLight: Color(0xFFB4C9BE),
    warmWhite: Color(0xFFF4F7F5),
    background: Color(0xFFEAF0EC),
    typography: KaliTypography.natureTypography,
  );

  static final KaliColorsExtension magentaTheme = KaliColorsExtension(
    espresso: Color(0xFF3B1B2B), // Deep Berry
    espressoL: Color(0xFF5A2C44),
    clay: Color(0xFFD17C9B),     // Vivid Dusty Rose
    clayDark: Color(0xFFA65876),
    sand: Color(0xFFF6E8EE),     // Pale Pink Surface
    sand2: Color(0xFFEAD2DD),
    sage: Color(0xFF9E7C88),
    sageLight: Color(0xFFC7AFB8),
    warmWhite: Color(0xFFF9F5F6),
    background: Color(0xFFF0EAEB),
    typography: KaliTypography.magentaTypography,
  );

  static final KaliColorsExtension oceanDarkTheme = KaliColorsExtension(
    espresso: const Color(0xFFE2E8F0),
    espressoL: const Color(0xFF94A3B8),
    clay: const Color(0xFF3B82F6),
    clayDark: const Color(0xFF2563EB),
    sand: const Color(0xFF1E293B),
    sand2: const Color(0xFF0F172A),
    sage: const Color(0xFF0EA5E9),
    sageLight: const Color(0xFF334155),
    warmWhite: const Color(0xFF0F172A),
    background: const Color(0xFF020617),
    typography: KaliTypography.oceanTypography,
  );

  static final KaliColorsExtension natureDarkTheme = KaliColorsExtension(
    espresso: const Color(0xFFD1D5DB),
    espressoL: const Color(0xFF9CA3AF),
    clay: const Color(0xFF10B981),
    clayDark: const Color(0xFF059669),
    sand: const Color(0xFF1F2937),
    sand2: const Color(0xFF111827),
    sage: const Color(0xFF34D399),
    sageLight: const Color(0xFF374151),
    warmWhite: const Color(0xFF111827),
    background: const Color(0xFF030712),
    typography: KaliTypography.natureTypography,
  );

  static final KaliColorsExtension magentaDarkTheme = KaliColorsExtension(
    espresso: const Color(0xFFE4E4E7),
    espressoL: const Color(0xFFA1A1AA),
    clay: const Color(0xFFEC4899),
    clayDark: const Color(0xFFDB2777),
    sand: const Color(0xFF27272A),
    sand2: const Color(0xFF18181B),
    sage: const Color(0xFFF472B6),
    sageLight: const Color(0xFF3F3F46),
    warmWhite: const Color(0xFF18181B),
    background: const Color(0xFF09090B),
    typography: KaliTypography.magentaTypography,
  );

  @override
  ThemeExtension<KaliColorsExtension> copyWith({
    Color? espresso,
    Color? espressoL,
    Color? clay,
    Color? clayDark,
    Color? sand,
    Color? sand2,
    Color? sage,
    Color? sageLight,
    Color? warmWhite,
    Color? background,
    KaliTypography? typography,
  }) {
    return KaliColorsExtension(
      espresso: espresso ?? this.espresso,
      espressoL: espressoL ?? this.espressoL,
      clay: clay ?? this.clay,
      clayDark: clayDark ?? this.clayDark,
      sand: sand ?? this.sand,
      sand2: sand2 ?? this.sand2,
      sage: sage ?? this.sage,
      sageLight: sageLight ?? this.sageLight,
      warmWhite: warmWhite ?? this.warmWhite,
      background: background ?? this.background,
      typography: typography ?? this.typography,
    );
  }

  @override
  ThemeExtension<KaliColorsExtension> lerp(
    covariant ThemeExtension<KaliColorsExtension>? other,
    double t,
  ) {
    if (other is! KaliColorsExtension) {
      return this;
    }
    return KaliColorsExtension(
      espresso: Color.lerp(espresso, other.espresso, t)!,
      espressoL: Color.lerp(espressoL, other.espressoL, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      clayDark: Color.lerp(clayDark, other.clayDark, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      sand2: Color.lerp(sand2, other.sand2, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageLight: Color.lerp(sageLight, other.sageLight, t)!,
      warmWhite: Color.lerp(warmWhite, other.warmWhite, t)!,
      background: Color.lerp(background, other.background, t)!,
      typography: typography.lerp(other.typography, t),
    );
  }

  /// Retorna un color legible (oscuro o claro) dependiendo de la luminancia del fondo
  Color getContrastColor(Color backgroundColor) {
    // Si la luminancia es mayor a 0.5 (color claro), retornamos espresso (oscuro).
    // De lo contrario, retornamos warmWhite (claro).
    return backgroundColor.computeLuminance() > 0.5 ? espresso : warmWhite;
  }
}

extension KaliColorsTypography on KaliColorsExtension {
  TextStyle display(Color color, {double size = 36}) => typography.display(color, size: size);
  TextStyle heading(Color color, {double size = 24}) =>
      typography.heading(color, size: size);
  TextStyle headingItalic(Color color, {double size = 26}) =>
      typography.headingItalic(color, size: size);
  TextStyle body(Color color,
          {double size = 13, FontWeight weight = FontWeight.w400}) =>
      typography.body(color, size: size, weight: weight);
  TextStyle label(Color color) => typography.label(color);
  TextStyle caption(Color color) => typography.caption(color);
  TextStyle loginDisplay(Color color) => typography.loginDisplay(color);
  TextStyle loginBody(Color color) => typography.loginBody(color);
}
