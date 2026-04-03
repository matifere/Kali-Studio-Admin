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

        if (state is AlumnosLoaded) {
          activeCount = state.students.length.toString();

          final now = DateTime.now();
          int thisMonthCount = 0;
          for (var s in state.students) {
            if (s.createdAt.year == now.year && s.createdAt.month == now.month) {
              thisMonthCount++;
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
            percentGrowthStr = '${percent.toStringAsFixed(1).replaceAll('.0', '')}%';
            isPositive = percent >= 0;
          }
        } else if (state is AlumnosError) {
          activeCount = '0';
        }

        return Row(
          children: [
            // Total Alumnos Activos (white card, wider)
            Expanded(
              flex: 5,
              child: _buildWhiteCard(
                title: 'TOTAL ALUMNOS ACTIVOS',
                value: activeCount,
                badge: Row(
                  children: [
                    Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositive
                            ? const Color(0xFF5C9E6C)
                            : const Color(0xFFD4685C)),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}$percentGrowthStr este mes',
                      style: KaliText.body(
                          isPositive
                              ? const Color(0xFF5C9E6C)
                              : const Color(0xFFD4685C),
                          weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Membresía Premium (clay warm card)
            Expanded(
              flex: 4,
              child: _buildClayCard(
                title: 'MEMBRESÍA PREMIUM',
                value: '48', // FIXME: Add logic to calculate premium members
              ),
            ),
            const SizedBox(width: 20),

            // Próximos Vencimientos (white card)
            Expanded(
              flex: 4,
              child: _buildWhiteCard(
                title: 'PRÓXIMOS VENCIMIENTOS',
                value: '12', // FIXME: Add logic to calculate expiring members
                badge: Text(
                  'En los próximos 7 días',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
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
              style:
                  KaliText.label(KaliColors.espresso.withValues(alpha: 0.5))),
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

  Widget _buildClayCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5D9B8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  KaliText.label(KaliColors.espresso.withValues(alpha: 0.7))),
          const SizedBox(height: 16),
          Text(
            value,
            style: KaliText.display(KaliColors.espresso).copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'alumnos con plan premium',
            style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
