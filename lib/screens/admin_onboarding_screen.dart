import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/pagos/plan_form_dialog.dart';

class AdminOnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const AdminOnboardingScreen({super.key, required this.onCompleted});

  @override
  State<AdminOnboardingScreen> createState() => _AdminOnboardingScreenState();
}

class _AdminOnboardingScreenState extends State<AdminOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _planCreated = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1 && !_planCreated) {
      // Obligatorio crear plan en el paso 1 (índice 1)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, crea tu primer plan para continuar.')),
      );
      return;
    }
    
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return Scaffold(
      backgroundColor: kaliColors.warmWhite,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header (Progress dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? kaliColors.espresso
                            : kaliColors.espresso.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Evita deslizar sin validar
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWelcomeSlide(kaliColors),
                      _buildPlansSlide(kaliColors),
                      _buildTrainersSlide(kaliColors),
                      _buildStudentsSlide(kaliColors),
                      _buildShiftsSlide(kaliColors),
                      _buildThemesSlide(kaliColors),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer (Buttons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: Text(
                          'Atrás',
                          style: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.6), weight: FontWeight.w600),
                        ),
                      )
                    else
                      const SizedBox(width: 80), // Placeholder to keep the 'Siguiente' button on the right

                    ElevatedButton(
                      onPressed: (_currentPage == 1 && !_planCreated) ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kaliColors.espresso,
                        foregroundColor: kaliColors.warmWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: kaliColors.espresso.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        _currentPage == 5 ? '¡Empezar!' : 'Siguiente',
                        style: kaliColors.body(
                          _currentPage == 1 && !_planCreated
                            ? kaliColors.espresso.withValues(alpha: 0.65)
                            : kaliColors.warmWhite,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideBase({
    required KaliColorsExtension kaliColors,
    required IconData icon,
    required String title,
    required String description,
    Widget? extraAction,
    Widget? customIconWidget,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        customIconWidget ?? Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kaliColors.espressoL.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 80,
            color: kaliColors.espresso,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: kaliColors.heading(kaliColors.espresso, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.7), size: 16),
        ),
        if (extraAction != null) ...[
          const SizedBox(height: 40),
          extraAction,
        ],
      ],
    );
  }

  Widget _buildWelcomeSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.waving_hand_rounded,
      title: '¡Bienvenido a Argity Turnos!',
      description: 'Estamos felices de tenerte acá. Argity Turnos es tu herramienta integral para gestionar alumnos, pagos, clases y a todo tu equipo de profesores.\n\nVamos a prepararlo todo en unos simples pasos.',
    );
  }

  Widget _buildPlansSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.card_membership_rounded,
      title: 'Creación de Planes',
      description: 'El primer paso indispensable es crear un plan de pagos (ej. Pase Libre, 2 Clases por semana). Los alumnos necesitarán un plan para poder reservar sus clases.',
      extraAction: _planCreated
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5C9E6C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5C9E6C).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF5C9E6C)),
                  const SizedBox(width: 8),
                  Text(
                    '¡Plan creado con éxito!',
                    style: kaliColors.body(const Color(0xFF5C9E6C), weight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => PlanFormDialog(
                    onRefresh: () {
                      if (mounted) {
                        setState(() {
                          _planCreated = true;
                        });
                      }
                    },
                  ),
                );
              },
              icon: Icon(Icons.add, color: kaliColors.getContrastColor(kaliColors.espresso)),
              label: Text('Crear mi primer plan', style: kaliColors.body(kaliColors.getContrastColor(kaliColors.espresso), weight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kaliColors.espresso,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }

  Widget _buildTrainersSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.sports_gymnastics_rounded,
      title: 'Tus Profesores',
      description: 'Desde la sección "Profesores" vas a poder invitar a tu equipo de trabajo. Ellos tendrán acceso para ver sus clases, tomar asistencia y gestionar a los alumnos.',
    );
  }

  Widget _buildStudentsSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.people_outline_rounded,
      title: 'Tus Alumnos',
      description: 'Mantené toda la información de tus alumnos en un solo lugar. Vas a poder ver su estado de pagos y cuántas clases les quedan. Recordá que tus alumnos deben tener un plan activo asignado para poder reservar clases desde su aplicación.',
    );
  }

  Widget _buildShiftsSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.calendar_today_rounded,
      title: 'Gestión de Clases',
      description: 'Creá tu grilla de horarios en el Calendario. Los alumnos podrán reservar su lugar desde la app para alumnos, y los profesores podrán controlar quiénes asisten.',
    );
  }

  Widget _buildThemesSlide(KaliColorsExtension kaliColors) {
    return _buildSlideBase(
      kaliColors: kaliColors,
      icon: Icons.palette_outlined,
      customIconWidget: _PremiumIconAnimation(kaliColors: kaliColors),
      title: 'Personalizá tu Estudio (Pro)',
      description: 'La personalización del estudio es una función premium exclusiva del plan Pro. Vas a poder adaptar los colores y estilos de la aplicación para que coincida con tu identidad visual.\n\n¡Todo listo para empezar a trabajar!',
    );
  }
}

class _PremiumIconAnimation extends StatefulWidget {
  final KaliColorsExtension kaliColors;
  const _PremiumIconAnimation({required this.kaliColors});

  @override
  State<_PremiumIconAnimation> createState() => _PremiumIconAnimationState();
}

class _PremiumIconAnimationState extends State<_PremiumIconAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Efecto de flotación mucho más sutil y suave
        final dy = math.sin(_controller.value * 2 * math.pi) * 4.0;
        
        // Efecto de brillo metálico (Shimmer)
        final slide = _controller.value * 3.0 - 1.0;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.kaliColors.espressoL.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.kaliColors.espressoL.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(slide - 0.5, -0.5),
                  end: Alignment(slide + 0.5, 0.5),
                  colors: const [
                    Color(0xFFD4AF37), // Dorado base
                    Color(0xDDFFF7D6), // Brillo metálico más suave/translúcido
                    Color(0xFFD4AF37), // Dorado base
                  ],
                  stops: const [0.1, 0.5, 0.9], // Transición mucho más amplia y difuminada
                ).createShader(bounds);
              },
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 80,
                color: Colors.white, // Color provisto por el ShaderMask
              ),
            ),
          ),
        );
      },
    );
  }
}
