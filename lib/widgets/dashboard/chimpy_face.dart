import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Avatar de Chimpy: ahora utiliza una animación Lottie.
class ChimpyFace extends StatelessWidget {
  final double size;

  const ChimpyFace({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: kaliColors.sand,
        child: Padding(
          padding: EdgeInsets.all(size * 0.15),
          child: Lottie.asset(
            'assets/lottie/see_no_evil.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
