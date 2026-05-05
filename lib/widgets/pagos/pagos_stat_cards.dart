import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Tarjetas de estadísticas de la sección de pagos.
class PagosStatCards extends StatelessWidget {
  const PagosStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagosBloc, PagosState>(
      builder: (context, state) {
        double revenue = 0.0;
        double outstandingAmount = 0.0;
        int outstandingCount = 0;
        double paidPercentage = 0.0;

        if (state is PagosLoaded) {
          revenue = state.monthlyRevenue;
          outstandingAmount = state.outstandingAmount;
          outstandingCount = state.outstandingCount;
          paidPercentage = state.paidSessionsPercentage;
        }

        return Row(
          children: [
            // Ingresos Mensuales
            Expanded(
              flex: 5,
              child: _RevenueCard(revenue: revenue),
            ),
            const SizedBox(width: 20),
            // Pendiente
            Expanded(
              flex: 4,
              child: _OutstandingCard(
                amount: outstandingAmount,
                count: outstandingCount,
              ),
            ),
            const SizedBox(width: 20),
            // Sesiones Pagadas
            Expanded(
              flex: 3,
              child: _PaidSessionsCard(percentage: paidPercentage),
            ),
          ],
        );
      },
    );
  }
}

String _getMonthName(int month) {
  const months = [
    '',
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE'
  ];
  return month >= 1 && month <= 12 ? months[month] : '';
}

// ─── Ingresos Mensuales ───────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final double revenue;
  
  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final currentMonthName = _getMonthName(DateTime.now().month);
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INGRESOS MENSUALES ($currentMonthName)',
            style: KaliText.label(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${revenue.toStringAsFixed(2)}',
            style: KaliText.display(KaliColors.espresso).copyWith(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: Color(0xFF5C9E6C)),
              const SizedBox(width: 4),
              Text(
                'Datos en tiempo real',
                style: KaliText.body(
                  const Color(0xFF5C9E6C),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pendiente ────────────────────────────────────────────────────────────────
class _OutstandingCard extends StatelessWidget {
  final double amount;
  final int count;

  const _OutstandingCard({required this.amount, required this.count});

  @override
  Widget build(BuildContext context) {
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENDIENTE',
            style: KaliText.label(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: KaliText.display(KaliColors.espresso).copyWith(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count facturas pendientes',
            style: KaliText.body(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sesiones Pagadas ─────────────────────────────────────────────────────────
class _PaidSessionsCard extends StatelessWidget {
  final double percentage;

  const _PaidSessionsCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESIONES PAGADAS',
            style: KaliText.label(
              KaliColors.warmWhite.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: KaliText.display(KaliColors.warmWhite).copyWith(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(KaliColors.sand),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
