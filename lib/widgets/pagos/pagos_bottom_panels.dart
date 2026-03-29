import 'package:flutter/material.dart';
import 'package:kali_studio/data/mock_payments.dart';
import 'package:kali_studio/models/payment.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Paneles inferiores de la sección de pagos:
/// desglose de métodos y actividad del libro contable.
class PagosBottomPanels extends StatelessWidget {
  const PagosBottomPanels({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MethodsBreakdown()),
        SizedBox(width: 24),
        Expanded(child: _LedgerActivity()),
      ],
    );
  }
}

// ─── Desglose de Métodos ──────────────────────────────────────────────────────
class _MethodsBreakdown extends StatelessWidget {
  const _MethodsBreakdown();

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
            'Desglose de Métodos',
            style: KaliText.headingItalic(KaliColors.espresso, size: 20),
          ),
          const SizedBox(height: 24),
          const _MethodBar(
            label: 'Tarjeta de Crédito',
            percent: 45,
            color: Color(0xFFD4B896),
          ),
          const SizedBox(height: 18),
          const _MethodBar(
            label: 'Transferencia',
            percent: 35,
            color: Color(0xFF9EAFC2),
          ),
          const SizedBox(height: 18),
          const _MethodBar(
            label: 'Efectivo',
            percent: 20,
            color: Color(0xFFB5C9B0),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de progreso de método ──────────────────────────────────────────────
class _MethodBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const _MethodBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KaliText.body(
                KaliColors.espresso,
                weight: FontWeight.w500,
                size: 13,
              ),
            ),
            Text(
              '$percent%',
              style: KaliText.body(
                KaliColors.espresso,
                weight: FontWeight.w700,
                size: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: KaliColors.sand,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Actividad del Libro Contable ─────────────────────────────────────────────
class _LedgerActivity extends StatelessWidget {
  const _LedgerActivity();

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
            'Actividad del Libro Contable',
            style: KaliText.headingItalic(KaliColors.espresso, size: 20),
          ),
          const SizedBox(height: 20),
          ...kMockLedgerEntries.map(
            (entry) => _LedgerRow(entry: entry),
          ),
        ],
      ),
    );
  }
}

// ─── Fila del libro contable ──────────────────────────────────────────────────
class _LedgerRow extends StatelessWidget {
  final LedgerEntry entry;
  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 14),
            decoration: BoxDecoration(
              color: entry.isAlert
                  ? const Color(0xFFD4685C)
                  : KaliColors.espresso.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.timestamp,
                  style: KaliText.label(
                    entry.isAlert
                        ? const Color(0xFFD4685C)
                        : KaliColors.espresso.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: KaliText.body(
                    KaliColors.espresso.withValues(alpha: 0.7),
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
