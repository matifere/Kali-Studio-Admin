import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/dashboard/dashboard_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardStatCards extends StatelessWidget {
  const DashboardStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final percentage = (state.capacidadPorcentaje * 100).toInt();

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 700;

            final widgets = [
              _buildStatCard(
                title: 'INGRESOS TOTALES',
                value:
                    '\$${NumberFormat('#,###', 'es_ES').format(state.ingresosMensuales)}',
                icon: Icons.payments_outlined,
                bottomWidget: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: KaliColors.clay.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+12% vs mes anterior',
                    style: KaliText.label(KaliColors.espresso),
                  ),
                ),
              ),
              _buildStatCard(
                title: 'TURNOS ACTIVOS HOY',
                value: state.turnosActivosHoy.toString(),
                icon: Icons.event_available_outlined,
                bottomWidget: Text(
                  state.turnosActivosHoy > 0
                      ? "Sesiones programadas para hoy"
                      : "No hay sesiones hoy",
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                ),
              ),
              _buildDarkStatCard(
                title: 'ALUMNOS PRESENTES',
                value: state.alumnosPresentesHoy.toString(),
                icon: Icons.person_add_alt_1_outlined,
                capacityText: '$percentage% de capacidad diaria alcanzada',
                progress: state.capacidadPorcentaje,
              ),
            ];

            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widgets[0],
                  const SizedBox(height: 24),
                  widgets[1],
                  const SizedBox(height: 24),
                  widgets[2],
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: widgets[0]),
                  const SizedBox(width: 24),
                  Expanded(child: widgets[1]),
                  const SizedBox(width: 24),
                  Expanded(child: widgets[2]),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                  style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5))),
              Icon(icon, color: KaliColors.espresso, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: KaliText.display(KaliColors.espresso).copyWith(
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
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: KaliText.label(KaliColors.warmWhite.withValues(alpha: 0.6))),
              Icon(icon, color: KaliColors.warmWhite, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: KaliText.display(KaliColors.warmWhite).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  fontStyle: FontStyle.normal)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(KaliColors.sand),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(capacityText,
              style: KaliText.body(KaliColors.warmWhite.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
