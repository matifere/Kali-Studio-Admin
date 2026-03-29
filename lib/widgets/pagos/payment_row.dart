import 'package:flutter/material.dart';
import 'package:kali_studio/models/payment.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Fila de la tabla de pagos.
class PaymentRow extends StatefulWidget {
  final Payment payment;
  const PaymentRow({super.key, required this.payment});

  @override
  State<PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<PaymentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered
            ? KaliColors.sand.withValues(alpha: 0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Row(
          children: [
            // Alumno
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: p.avatarColor,
                    child: Text(
                      p.studentInitials,
                      style: KaliText.body(
                        KaliColors.espresso,
                        weight: FontWeight.w700,
                        size: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    p.studentName,
                    style: KaliText.body(
                      KaliColors.espresso,
                      weight: FontWeight.w600,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Referencia
            Expanded(
              flex: 3,
              child: Text(
                p.reference,
                style: KaliText.body(
                  KaliColors.espresso.withValues(alpha: 0.6),
                  size: 13,
                ),
              ),
            ),

            // Fecha
            Expanded(
              flex: 2,
              child: Text(
                p.date,
                style: KaliText.body(
                  KaliColors.espresso.withValues(alpha: 0.6),
                  size: 13,
                ),
              ),
            ),

            // Método
            Expanded(
              flex: 3,
              child: Text(
                p.methodLabel,
                style: KaliText.body(
                  KaliColors.espresso.withValues(alpha: 0.7),
                  size: 13,
                ),
              ),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: _StatusBadge(payment: p),
            ),

            // Monto
            Expanded(
              flex: 2,
              child: Text(
                p.amountFormatted,
                style: KaliText.body(
                  KaliColors.espresso,
                  weight: FontWeight.w700,
                  size: 15,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de estado ──────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Payment payment;
  const _StatusBadge({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: payment.statusBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          payment.statusLabel,
          style: KaliText.label(payment.statusColor)
              .copyWith(fontSize: 8, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
