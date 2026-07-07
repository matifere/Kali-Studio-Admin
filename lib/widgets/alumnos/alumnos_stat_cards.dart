import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';

class AlumnosStatCards extends StatelessWidget {
  const AlumnosStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocBuilder<AlumnosBloc, AlumnosState>(
      builder: (context, state) {
        String? activeCount;
        String percentGrowthStr = '0%';
        bool isPositive = true;

        // ── Contar por plan en O(n) y Vencimientos ─────────────────────────
        final Map<String, int> countByPlan = {};
        int expiringCount = 0;

        if (state is AlumnosLoaded) {
          final now = DateTime.now();
          final nextWeek = now.add(const Duration(days: 7));
          int thisMonthCount = 0;
          int activeStudents = 0;
          for (var s in state.students) {
            // La tarjeta y el badge de crecimiento son sobre ALUMNOS ACTIVOS:
            // solo contamos is_active == true, tanto el total como las altas
            // del mes, para que el número grande y el % sean coherentes.
            if (s.isActive) {
              activeStudents++;
              if (s.createdAt.year == now.year &&
                  s.createdAt.month == now.month) {
                thisMonthCount++;
              }
            }
            // Aprovechar el mismo bucle para contar por plan
            final plan = s.plan.isNotEmpty ? s.plan : 'Sin plan';
            countByPlan[plan] = (countByPlan[plan] ?? 0) + 1;

            // Contar vencimientos próximos
            if (s.planEndDate != null) {
              // Si vence entre hoy (o antes pero sigue activo) y los próximos 7 días
              // o simplemente si el vencimiento cae en los próximos 7 días a partir de hoy.
              // Para ser seguros, si ya venció (y por alguna razón sigue en esta lista) o vence en la próxima semana:
              if (s.planEndDate!.isBefore(nextWeek) &&
                  s.planEndDate!
                      .isAfter(now.subtract(const Duration(days: 1)))) {
                expiringCount++;
              }
            }
          }

          activeCount = activeStudents.toString();

          // Base = alumnos activos que ya existían antes de este mes.
          int previousTotal = activeStudents - thisMonthCount;
          if (previousTotal == 0) {
            if (thisMonthCount > 0) {
              percentGrowthStr = '100+%';
              isPositive = true;
            } else {
              percentGrowthStr = '0%';
              isPositive = true;
            }
          } else {
            double percent = (thisMonthCount / previousTotal) * 100;
            percentGrowthStr =
                '${percent.toStringAsFixed(1).replaceAll('.0', '')}%';
            isPositive = percent >= 0;
          }
        } else if (state is AlumnosError) {
          activeCount = '0';
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 900;

            final children = [
              _buildWhiteCard(
                title: 'TOTAL ALUMNOS ACTIVOS',
                value: activeCount,
                badge: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositive
                          ? const Color(0xFF5C9E6C)
                          : const Color(0xFFD4685C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}$percentGrowthStr este mes',
                      style: kaliColors.body(
                        isPositive
                            ? const Color(0xFF5C9E6C)
                            : const Color(0xFFD4685C),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                kaliColors: kaliColors,
              ),
              _PlanCarousel(
                countByPlan: countByPlan,
                isLoading: state is AlumnosLoading,
              ),
              _buildWhiteCard(
                title: 'PRÓXIMOS VENCIMIENTOS',
                value:
                    state is AlumnosLoading ? null : expiringCount.toString(),
                badge: Text(
                  'En los próximos 7 días',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.5)),
                ),
                kaliColors: kaliColors,
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  children[0],
                  const SizedBox(height: 20),
                  children[1],
                  const SizedBox(height: 20),
                  children[2],
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: children[0]),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: children[1]),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: children[2]),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildWhiteCard({
    required String title,
    required String? value,
    required Widget badge,
    required KaliColorsExtension kaliColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kaliColors.espresso.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  kaliColors.label(kaliColors.espresso.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          value != null
              ? Text(
                  value,
                  style: kaliColors.display(kaliColors.espresso).copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                )
              : const LinearProgressIndicator(),
          const SizedBox(height: 12),
          badge,
        ],
      ),
    );
  }
}

// ── Carrusel de Planes ─────────────────────────────────────────────────────────
//
// Muestra un card por cada plan encontrado (datos reales del BLoC).
// Si hay más de un plan, aparecen indicadores de página y flechas de navegación.
class _PlanCarousel extends StatefulWidget {
  final Map<String, int> countByPlan;
  final bool isLoading;

  const _PlanCarousel({required this.countByPlan, required this.isLoading});

  @override
  State<_PlanCarousel> createState() => _PlanCarouselState();
}

class _PlanCarouselState extends State<_PlanCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mientras carga, mostrar skeleton
    if (widget.isLoading) {
      return const _ClayPlanCard(planName: '...', count: null);
    }

    final entries = widget.countByPlan.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Mayor primero

    if (entries.isEmpty) {
      return const _ClayPlanCard(planName: 'Sin datos', count: 0);
    }

    if (entries.length == 1) {
      return _ClayPlanCard(
        planName: entries[0].key,
        count: entries[0].value,
      );
    }

    // Múltiples planes → carrusel con indicadores y flechas
    return Stack(
      children: [
        SizedBox(
          height: 195, // altura fija para no depender del contenido variable
          child: PageView.builder(
            controller: _pageController,
            itemCount: entries.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return _ClayPlanCard(
                planName: entries[index].key,
                count: entries[index].value,
                showPager: true,
                currentPage: _currentPage,
                totalPages: entries.length,
              );
            },
          ),
        ),

        // Flecha izquierda
        if (_currentPage > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(_currentPage - 1),
              ),
            ),
          ),

        // Flecha derecha
        if (_currentPage < entries.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(_currentPage + 1),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Card individual de plan ────────────────────────────────────────────────────
class _ClayPlanCard extends StatelessWidget {
  final String planName;
  final int? count; // null = cargando
  final bool showPager;
  final int currentPage;
  final int totalPages;

  const _ClayPlanCard({
    required this.planName,
    required this.count,
    this.showPager = false,
    this.currentPage = 0,
    this.totalPages = 1,
  });

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kaliColors.clay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planName.toUpperCase(),
                  style: kaliColors
                      .label(kaliColors.espresso.withValues(alpha: 0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Indicadores de página (dots)
              if (showPager)
                Row(
                  children: List.generate(
                    totalPages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 4),
                      width: i == currentPage ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == currentPage
                            ? kaliColors.espresso
                            : kaliColors.espresso.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          count != null
              ? Text(
                  count.toString(),
                  style: kaliColors.display(kaliColors.espresso).copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                )
              : const SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(),
                ),
          const SizedBox(height: 12),
          Text(
            count == 1 ? 'alumno con este plan' : 'alumnos con este plan',
            style: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ── Botón de navegación del carrusel ──────────────────────────────────────────
class _NavArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered
                ? kaliColors.espresso.withValues(alpha: 0.15)
                : kaliColors.espresso.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: kaliColors.espresso.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
