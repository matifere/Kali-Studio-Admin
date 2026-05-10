import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';

class AlumnosStatCards extends StatelessWidget {
  const AlumnosStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlumnosBloc, AlumnosState>(
      builder: (context, state) {
        String? activeCount;
        String percentGrowthStr = '0%';
        bool isPositive = true;

        // ── Contar por plan en O(n) y Vencimientos ─────────────────────────
        final Map<String, int> countByPlan = {};
        int expiringCount = 0;

        if (state is AlumnosLoaded) {
          activeCount = state.students.length.toString();

          final now = DateTime.now();
          final nextWeek = now.add(const Duration(days: 7));
          int thisMonthCount = 0;
          for (var s in state.students) {
            if (s.createdAt.year == now.year && s.createdAt.month == now.month) {
              thisMonthCount++;
            }
            // Aprovechar el mismo bucle para contar por plan
            final plan = s.plan.isNotEmpty ? s.plan : 'Sin plan';
            countByPlan[plan] = (countByPlan[plan] ?? 0) + 1;

            // Contar vencimientos próximos
            if (s.planEndDate != null) {
              // Si vence entre hoy (o antes pero sigue activo) y los próximos 7 días
              // o simplemente si el vencimiento cae en los próximos 7 días a partir de hoy.
              // Para ser seguros, si ya venció (y por alguna razón sigue en esta lista) o vence en la próxima semana:
              if (s.planEndDate!.isBefore(nextWeek) && s.planEndDate!.isAfter(now.subtract(const Duration(days: 1)))) {
                expiringCount++;
              }
            }
          }

          int previousTotal = state.students.length - thisMonthCount;
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
                      style: KaliText.body(
                        isPositive
                            ? const Color(0xFF5C9E6C)
                            : const Color(0xFFD4685C),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _PlanCarousel(
                countByPlan: countByPlan,
                isLoading: state is AlumnosLoading,
              ),
              _buildWhiteCard(
                title: 'PRÓXIMOS VENCIMIENTOS',
                value: state is AlumnosLoading ? null : expiringCount.toString(),
                badge: Text(
                  'En los próximos 7 días',
                  style: KaliText.body(
                      KaliColors.espresso.withValues(alpha: 0.5)),
                ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          value != null
              ? Text(
                  value,
                  style: KaliText.display(KaliColors.espresso).copyWith(
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
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mientras carga, mostrar skeleton
    if (widget.isLoading) {
      return _ClayPlanCard(planName: '...', count: null);
    }

    final entries = widget.countByPlan.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Mayor primero

    if (entries.isEmpty) {
      return _ClayPlanCard(planName: 'Sin datos', count: 0);
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
          height: 185, // altura fija para no depender del contenido variable
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5D9B8),
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
                  style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.7)),
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
                            ? KaliColors.espresso
                            : KaliColors.espresso.withValues(alpha: 0.25),
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
                  style: KaliText.display(KaliColors.espresso).copyWith(
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
            style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered
                ? KaliColors.espresso.withValues(alpha: 0.15)
                : KaliColors.espresso.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: KaliColors.espresso.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
