import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/navigation/navigation_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/dashboard/chimpy_assistant.dart';
import 'package:argrity/widgets/dashboard/chimpy_face.dart';
import 'package:argrity/widgets/dashboard/sidebar.dart';
import 'package:argrity/widgets/dashboard/stat_cards.dart';
import 'package:argrity/widgets/dashboard/schedule_list.dart';
import 'package:argrity/screens/alumnos_screen.dart';
import 'package:argrity/screens/entrenadores_screen.dart';
import 'package:argrity/screens/turnos_screen.dart';
import 'package:argrity/screens/pagos_screen.dart';
import 'package:argrity/screens/settings/settings_theme_screen.dart';
import 'package:argrity/screens/settings/settings_subscription_screen.dart';
import 'package:argrity/screens/settings/settings_account_screen.dart';
import 'package:argrity/screens/settings/settings_institution_screen.dart';
import 'package:argrity/bloc/dashboard/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _buildCurrentPage(String page) {
    switch (page) {
      case 'Alumnos':
        return const AlumnosScreen();
      case 'Entrenadores':
        return const EntrenadoresScreen();
      case 'Turnos':
        return const TurnosScreen();
      case 'Pagos':
        return const PagosScreen();
      case 'Cuenta':
        return const SettingsAccountScreen();
      case 'Institución':
        return const SettingsInstitutionScreen();
      case 'Suscripción':
        return const SettingsSubscriptionScreen();
      case 'Tema':
        return const SettingsThemeScreen();
      default:
        return const _DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          backgroundColor: kaliColors.warmWhite,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: kaliColors.warmWhite,
                  elevation: 0,
                  iconTheme: IconThemeData(color: kaliColors.espresso),
                  title: Text(
                    'Argity',
                    style: kaliColors
                        .heading(kaliColors.espresso, size: 20)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          drawer: isMobile
              ? Drawer(
                  child: DashboardSidebar(
                    currentPage: navState.currentPage,
                    onNavigate: (page) {
                      context.read<NavigationBloc>().add(
                            NavigationPageChanged(page),
                          );
                      Navigator.of(context).pop(); // Cerrar drawer al navegar
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile)
                DashboardSidebar(
                  currentPage: navState.currentPage,
                  onNavigate: (page) {
                    context.read<NavigationBloc>().add(
                          NavigationPageChanged(page),
                        );
                  },
                ),
              Expanded(child: _buildCurrentPage(navState.currentPage)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Dashboard home content ───────────────────────────────────────────────────
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _chimpyOpen = false;

  // Cada incremento dispara la lluvia de corazones de Chimpy.
  int _heartsTrigger = 0;

  void _toggleChimpy() {
    setState(() {
      _chimpyOpen = !_chimpyOpen;
      _heartsTrigger++;
    });
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DashboardBloc>();
    if (!bloc.state.isLoading) {
      bloc.add(DashboardLoadRequested());
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 20 : 40,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado con Chimpy colgado del final del saludo
                    // ("Buenas noches," o lo que toque), visible solo con el
                    // chat abierto. El bloque reserva el alto del mono entero
                    // para que la cola no quede tapada por las stat cards ni
                    // salte el layout al aparecer.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final greetingStyle = kaliColors
                            .heading(kaliColors.espresso,
                                size: isSmall ? 32 : 40)
                            .copyWith(fontWeight: FontWeight.w600);
                        final textPainter = TextPainter(
                          text: TextSpan(
                              text: _greeting, style: greetingStyle),
                          textDirection: TextDirection.ltr,
                        )..layout();
                        final monkeyW = isSmall ? 78.0 : 96.0;
                        final monkeyH = monkeyW * 3910 / 2600;
                        final monkeyTop = isSmall ? 26.0 : 34.0;
                        // La mano del mono (38% del ancho del PNG) queda
                        // apenas después de la última palabra del saludo.
                        final monkeyLeft = (textPainter.width -
                                monkeyW * 0.30)
                            .clamp(0.0, constraints.maxWidth - monkeyW);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(_greeting,
                                    style: greetingStyle, maxLines: 1),
                                const SizedBox(height: 8),
                                Text(
                                  'Esto es lo que está pasando hoy.',
                                  style: kaliColors.body(
                                    kaliColors.espresso
                                        .withValues(alpha: 0.6),
                                    size: 16,
                                  ),
                                ),
                                // Deja lugar para el mono completo, cola
                                // incluida, antes de las stat cards.
                                SizedBox(
                                  height: monkeyTop + monkeyH + 12 -
                                      (isSmall ? 66 : 80),
                                ),
                              ],
                            ),
                            // El mono baja por su liana solo cuando el chat
                            // está abierto (se abre con el botón flotante);
                            // tocarlo también cierra el chat.
                            Positioned(
                              top: monkeyTop,
                              left: monkeyLeft,
                              child: IgnorePointer(
                                ignoring: !_chimpyOpen,
                                child: AnimatedScale(
                                  scale: _chimpyOpen ? 1 : 0,
                                  alignment: Alignment.topCenter,
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  child: GestureDetector(
                                    onTap: _toggleChimpy,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: ChimpyHangingVine(
                                          width: monkeyW),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Corazones que suelta Chimpy al tocarlo.
                            Positioned(
                              top: monkeyTop - monkeyH * 0.35,
                              left: monkeyLeft - monkeyW * 0.20,
                              child: IgnorePointer(
                                child: _ChimpyHearts(
                                  trigger: _heartsTrigger,
                                  width: monkeyW * 1.4,
                                  height: monkeyH * 0.9,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const DashboardStatCards(),
                    const SizedBox(height: 32),
                    const DashboardScheduleList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: isSmall ? 16 : 24,
          bottom: isSmall ? 16 : 24,
          child: ChimpyAssistant(
            open: _chimpyOpen,
            onToggle: _toggleChimpy,
          ),
        ),
      ],
    );
  }
}
/// Corazoncitos que Chimpy suelta al tocarlo: nacen cerca de su cabeza,
/// flotan hacia arriba abriéndose y se desvanecen. Cada incremento de
/// [trigger] reproduce la animación.
class _ChimpyHearts extends StatefulWidget {
  final int trigger;
  final double width;
  final double height;

  const _ChimpyHearts({
    required this.trigger,
    required this.width,
    required this.height,
  });

  @override
  State<_ChimpyHearts> createState() => _ChimpyHeartsState();
}

class _ChimpyHeartsState extends State<_ChimpyHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  // Parámetros fijos por corazón: deriva horizontal, altura de subida,
  // arranque escalonado, emoji y tamaño relativo.
  static const _drift = [-0.38, 0.32, -0.12, 0.42, 0.06, -0.30];
  static const _rise = [0.95, 0.80, 1.0, 0.70, 0.90, 0.62];
  static const _delay = [0.0, 0.08, 0.16, 0.05, 0.22, 0.12];
  static const _emoji = ['❤️', '💕', '🧡', '💖', '❤️', '💛'];
  static const _size = [0.20, 0.15, 0.17, 0.13, 0.22, 0.14];

  @override
  void didUpdateWidget(_ChimpyHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating) return const SizedBox.shrink();
          final t = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _emoji.length; i++)
                _heart(i, t, w, h),
            ],
          );
        },
      ),
    );
  }

  Widget _heart(int i, double t, double w, double h) {
    // Progreso propio del corazón i (arranque escalonado).
    final p = ((t - _delay[i]) / (1 - _delay[i])).clamp(0.0, 1.0);
    if (p == 0) return const SizedBox.shrink();
    // Nace a la altura de la cabeza y sube abriéndose en abanico.
    final x = w * 0.55 + _drift[i] * w * 0.5 * p;
    final y = h * 0.80 - _rise[i] * h * 0.75 * p;
    final opacity = p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85;
    final scale = 0.5 + 0.7 * p;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Text(
            _emoji[i],
            style: TextStyle(fontSize: w * _size[i]),
          ),
        ),
      ),
    );
  }
}
