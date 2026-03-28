import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardRecentActivity extends StatelessWidget {
  const DashboardRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Actividad Reciente",
            style: KaliText.headingItalic(KaliColors.espresso, size: 28).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          _buildActivityItem(
            timeLabel: 'HACE 10 MIN',
            title: 'Nuevo Alumno Registrado',
            subtitle: 'María García se unió al plan Morning Flow.',
          ),
          _buildActivityItem(
            timeLabel: 'HACE 45 MIN',
            title: 'Pago Recibido',
            subtitle: 'Transacción #8842 de Robert Chen confirmada.',
          ),
          _buildActivityItem(
            timeLabel: 'HACE 2 HORAS',
            title: 'Clase Cancelada',
            subtitle: 'Ashtanga de tarde cancelado por enfermedad.',
          ),
          _buildActivityItem(
            timeLabel: 'HACE 3 HORAS',
            title: 'Nueva Reseña',
            subtitle: 'Calificación de 5 estrellas de Lucía P. "¡Me encanta la onda!"',
            isLast: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: Text(
                'VER TODA LA ACTIVIDAD',
                style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.6)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String timeLabel,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: KaliColors.clayDark, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: KaliColors.espresso.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
