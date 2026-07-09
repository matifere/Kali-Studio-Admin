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

/// Chimpy colgado de una liana (assets/images/chimpy.png), balanceándose
/// suave desde el punto donde la mano agarra la liana. Pensado para colgarlo
/// de un texto o encabezado.
class ChimpyHangingVine extends StatefulWidget {
  final double width;
  const ChimpyHangingVine({super.key, this.width = 90});

  @override
  State<ChimpyHangingVine> createState() => _ChimpyHangingVineState();
}

class _ChimpyHangingVineState extends State<ChimpyHangingVine>
    with SingleTickerProviderStateMixin {
  // Relación de aspecto del PNG (2600x3910).
  static const _aspect = 3910 / 2600;

  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * _aspect;
    // Punto de agarre en la imagen: la mano sobre la liana (pivote del
    // balanceo).
    final grip = Offset(w * 0.38, h * 0.12);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _swing,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_swing.value);
          final angle = (t - 0.5) * 0.09;
          return Transform.rotate(
            angle: angle,
            origin: Offset(grip.dx - w / 2, grip.dy - h / 2),
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/chimpy.png',
          width: w,
          height: h,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          // El PNG original es 2600px de ancho: decodificar achicado para no
          // gastar memoria.
          cacheWidth: (w * dpr).round(),
        ),
      ),
    );
  }
}
