import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/dashboard/dashboard_bloc.dart';
import 'package:intl/intl.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/services/profile_cache.dart';

class DashboardStatCards extends StatelessWidget {
  const DashboardStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final percentage = (state.capacidadPorcentaje * 100).toInt();

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 700;

            if (state.isLoading && !state.hasLoaded) {
              return _buildSkeletonRow(isNarrow: isNarrow, kaliColors: kaliColors);
            }

            final widgets = <Widget>[];

            if (ProfileCache.isSudo) {
              widgets.add(
                _buildStatCard(
                  title: 'INGRESOS MENSUALES',
                  value:
                      '\$${NumberFormat('#,###', 'es_ES').format(state.ingresosMensuales)}',
                  icon: Icons.payments_outlined,
                  bottomWidget: Text(
                    'Suscripciones activas',
                    style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
                  ),
                  kaliColors: kaliColors,
                ),
              );
            }

            widgets.add(
              _buildStatCard(
                title: 'TURNOS ACTIVOS HOY',
                value: state.turnosActivosHoy.toString(),
                icon: Icons.event_available_outlined,
                bottomWidget: Text(
                  state.turnosActivosHoy > 0
                      ? "Sesiones programadas para hoy"
                      : "No hay sesiones hoy",
                  style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                kaliColors: kaliColors,
              ),
            );

            widgets.add(
              _buildDarkStatCard(
                title: 'ALUMNOS PRESENTES',
                value: state.alumnosPresentesHoy.toString(),
                icon: Icons.person_add_alt_1_outlined,
                capacityText: '$percentage% de capacidad diaria alcanzada',
                progress: state.capacidadPorcentaje,
                kaliColors: kaliColors,
              ),
            );

            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widgets.length; i++) ...[
                    widgets[i],
                    if (i < widgets.length - 1) const SizedBox(height: 24),
                  ]
                ],
              );
            } else {
              return Row(
                children: [
                  for (int i = 0; i < widgets.length; i++) ...[
                    Expanded(child: widgets[i]),
                    if (i < widgets.length - 1) const SizedBox(width: 24),
                  ]
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSkeletonRow({required bool isNarrow, required KaliColorsExtension kaliColors}) {
    final cardsCount = ProfileCache.isSudo ? 3 : 2;
    final cards = List.generate(cardsCount, (_) => _buildSkeletonCard(kaliColors));
    
    if (isNarrow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 24),
          ]
        ],
      );
    }
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 24),
        ]
      ],
    );
  }

  Widget _buildSkeletonCard(KaliColorsExtension kaliColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kaliColors.espresso.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 120,
            decoration: BoxDecoration(
              color: kaliColors.espresso.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 40,
            width: 80,
            decoration: BoxDecoration(
              color: kaliColors.espresso.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 12,
            width: 160,
            decoration: BoxDecoration(
              color: kaliColors.espresso.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Widget bottomWidget,
    required KaliColorsExtension kaliColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kaliColors.espresso.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: KaliText.label(kaliColors.espresso.withValues(alpha: 0.5))),
              Icon(icon, color: kaliColors.espresso, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: KaliText.display(kaliColors.espresso).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  fontStyle: FontStyle.normal)),
          const SizedBox(height: 16),
          bottomWidget,
        ],
      ),
    );
  }

  Widget _buildDarkStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String capacityText,
    required double progress,
    required KaliColorsExtension kaliColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kaliColors.espresso,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: KaliText.label(kaliColors.warmWhite.withValues(alpha: 0.6))),
              Icon(icon, color: kaliColors.warmWhite, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: KaliText.display(kaliColors.warmWhite).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  fontStyle: FontStyle.normal)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: kaliColors.warmWhite.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(kaliColors.sand),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(capacityText,
              style: KaliText.body(kaliColors.warmWhite.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
