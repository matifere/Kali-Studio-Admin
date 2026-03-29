import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Tarjetas de estadísticas de la sección de pagos.
class PagosStatCards extends StatelessWidget {
  const PagosStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        // Ingresos Mensuales
        Expanded(
          flex: 5,
          child: _RevenueCard(),
        ),
        SizedBox(width: 20),
        // Pendiente
        Expanded(
          flex: 4,
          child: _OutstandingCard(),
        ),
        SizedBox(width: 20),
        // Sesiones Pagadas
        Expanded(
          flex: 3,
          child: _PaidSessionsCard(),
        ),
      ],
    );
  }
}

// ─── Ingresos Mensuales ───────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

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
            'INGRESOS MENSUALES (MARZO)',
            style: KaliText.label(
              KaliColors.espresso.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$12,450.00',
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
                '+12.4% vs mes anterior',
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
  const _OutstandingCard();

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
            '\$2,140.00',
            style: KaliText.display(KaliColors.espresso).copyWith(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '8 facturas pendientes',
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
  const _PaidSessionsCard();

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
            '94%',
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
              value: 0.94,
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
