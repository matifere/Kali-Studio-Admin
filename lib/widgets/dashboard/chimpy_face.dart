import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Carita de Chimpy: recorte circular de la cara del PNG
/// (assets/images/chimpy.png), para los avatares del chat.
class ChimpyFace extends StatelessWidget {
  final double size;

  const ChimpyFace({super.key, required this.size});

  // Ventana de la cara dentro del PNG (fracciones del tamaño original,
  // verificadas recortando la imagen).
  static const _faceCenterX = 0.644;
  static const _faceCenterY = 0.307;
  static const _faceWidth = 0.558;
  static const _aspect = 3910 / 2600;

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final imgW = size / _faceWidth;
    final imgH = imgW * _aspect;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: kaliColors.sand,
        child: Stack(
          children: [
            Positioned(
              left: size / 2 - imgW * _faceCenterX,
              top: size / 2 - imgH * _faceCenterY,
              width: imgW,
              height: imgH,
              child: Image.asset(
                'assets/images/chimpy.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                cacheWidth: (imgW * dpr).round(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
