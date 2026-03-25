import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardStatCards extends StatelessWidget {
  const DashboardStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'INGRESOS TOTALES',
            value: '\$12,480',
            icon: Icons.payments_outlined,
            bottomWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: KaliColors.clay.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+12% vs mes anterior',
                style: KaliText.label(KaliColors.espresso),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            title: 'TURNOS ACTIVOS HOY',
            value: '24',
            icon: Icons.event_available_outlined,
            bottomWidget: Text(
              '8 sesiones completadas',
              style: KaliText.body(KaliColors.espresso.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDarkStatCard(
            title: 'ALUMNOS PRESENTES',
            value: '142',
            icon: Icons.person_add_alt_1_outlined,
            capacityText: '75% de capacidad diaria alcanzada',
            progress: 0.75,
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(0.02),
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
              Text(title, style: KaliText.label(KaliColors.espresso.withOpacity(0.5))),
              Icon(icon, color: KaliColors.espresso, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: KaliText.display(KaliColors.espresso).copyWith(fontWeight: FontWeight.bold, fontSize: 40, fontStyle: FontStyle.normal)),
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
              Text(title, style: KaliText.label(KaliColors.warmWhite.withOpacity(0.6))),
              Icon(icon, color: KaliColors.warmWhite, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: KaliText.display(KaliColors.warmWhite).copyWith(fontWeight: FontWeight.bold, fontSize: 40, fontStyle: FontStyle.normal)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(KaliColors.sand),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(capacityText, style: KaliText.body(KaliColors.warmWhite.withOpacity(0.6))),
        ],
      ),
    );
  }
}
