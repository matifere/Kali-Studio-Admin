import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardScheduleList extends StatelessWidget {
  const DashboardScheduleList({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cronograma de Hoy",
                style: KaliText.headingItalic(KaliColors.espresso, size: 28)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildScheduleItem(
            time: '08:00',
            period: 'AM',
            title: 'Vinyasa Flow Avanzado',
            coach: 'Profesor: Elena Moretti',
            occupancy: '18/20',
            occupancyPercent: '90%',
            dotColor: Colors.red,
          ),
          _buildScheduleItem(
            time: '10:30',
            period: 'AM',
            title: 'Hatha Básico',
            coach: 'Profesor: Julian Alvarez',
            occupancy: '12/20',
            occupancyPercent: '60%',
            dotColor: KaliColors.clayDark,
            isActive: true,
          ),
          _buildScheduleItem(
            time: '04:00',
            period: 'PM',
            title: 'Yin Yoga & Meditación',
            coach: 'Profesor: Elena Moretti',
            occupancy: '15/20',
            occupancyPercent: '75%',
            dotColor: KaliColors.clayDark,
          ),
          _buildScheduleItem(
            time: '06:30',
            period: 'PM',
            title: 'Power Pilates',
            coach: 'Profesor: Sarah Jenkins',
            occupancy: '20/20',
            occupancyPercent: 'SALA LLENA',
            isFull: true,
            dotColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String period,
    required String title,
    required String coach,
    required String occupancy,
    required String occupancyPercent,
    required Color dotColor,
    bool isActive = false,
    bool isFull = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: KaliText.heading(KaliColors.espresso, size: 20)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  period,
                  style: KaliText.label(
                      KaliColors.espresso.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          // Active indicator
          if (isActive)
            Container(
              width: 3,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: KaliColors.espresso,
                borderRadius: BorderRadius.circular(1.5),
              ),
            )
          else
            const SizedBox(width: 32),
          // Class Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KaliText.body(KaliColors.espresso,
                      weight: FontWeight.bold, size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  coach,
                  style: KaliText.body(
                      KaliColors.espresso.withValues(alpha: 0.6),
                      size: 13),
                ),
              ],
            ),
          ),
          // Occupancy
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    occupancy,
                    style: KaliText.body(KaliColors.espresso,
                        weight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              isFull
                  ? Text(
                      occupancyPercent,
                      style: KaliText.label(KaliColors.espresso),
                    )
                  : Text(
                      '$occupancyPercent OCUPACIÓN',
                      style: KaliText.label(
                          KaliColors.espresso.withValues(alpha: 0.5)),
                    ),
            ],
          )
        ],
      ),
    );
  }
}
