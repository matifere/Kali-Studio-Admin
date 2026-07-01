import 'package:flutter/material.dart';

class KaliColorsExtension extends ThemeExtension<KaliColorsExtension> {
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

  static KaliColorsExtension defaultTheme() {
    return const KaliColorsExtension(
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
    );
  }

  static KaliColorsExtension darkTheme() {
    return const KaliColorsExtension(
      espresso: Color(0xFFEFEFEF),
      espressoL: Color(0xFFFFFFFF),
      clay: Color(0xFFC4A882), // Accent keeping brand identity
      clayDark: Color(0xFFA08060),
      sand: Color(0xFF2C2C2C),
      sand2: Color(0xFF1A1A1A),
      sage: Color(0xFF455A64),
      sageLight: Color(0xFF37474F),
      warmWhite: Color(0xFF121212),
      background: Color(0xFF000000),
    );
  }

  static KaliColorsExtension oceanTheme() {
    return const KaliColorsExtension(
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
    );
  }

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
    );
  }
}
