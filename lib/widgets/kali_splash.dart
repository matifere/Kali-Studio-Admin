import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Pantalla de carga con branding. Se muestra mientras la app verifica la
/// sesión / perfil tras el login, en lugar de un scaffold en blanco.
///
/// El logo aparece con un fade + escala suave para que la transición desde
/// el login no se sienta abrupta.
class KaliSplash extends StatefulWidget {
  /// Mensaje opcional bajo el logo (ej. "Cargando tu panel...").
  final String? message;

  const KaliSplash({super.key, this.message});

  @override
  State<KaliSplash> createState() => _KaliSplashState();
}

class _KaliSplashState extends State<KaliSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Scaffold(
      backgroundColor: kaliColors.warmWhite,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/images/argity_logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Argity',
                style: kaliColors.heading(kaliColors.espresso, size: 30),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kaliColors.clayDark,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.message ?? 'Cargando tu panel...',
                style: kaliColors.body(
                  kaliColors.espresso.withValues(alpha: 0.55),
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
