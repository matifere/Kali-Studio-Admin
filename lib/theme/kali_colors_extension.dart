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
