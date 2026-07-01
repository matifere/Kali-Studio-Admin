import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/models/payment.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

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
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final p = widget.payment;

    final avatarColors = [kaliColors.clay, kaliColors.sand, kaliColors.sage];
    final avatarColor = avatarColors[p.studentName.length % avatarColors.length];

    return MouseRegion(
      onEnter: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true); },
      onExit: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false); },
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
                    backgroundColor: avatarColor,
                    child: Text(
                      p.studentInitials,
                      style: KaliText.body(
                        kaliColors.espresso,
                        weight: FontWeight.w600,
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
                  kaliColors.espresso.withValues(alpha: 0.6),
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
                  kaliColors.espresso.withValues(alpha: 0.6),
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
                  kaliColors.espresso.withValues(alpha: 0.7),
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
                  kaliColors.espresso,
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
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    
    Color statusBgColor;
    Color statusColor;
    switch (payment.status) {
      case PaymentStatus.completed:
        statusBgColor = kaliColors.sageLight;
        statusColor = kaliColors.sage;
        break;
      case PaymentStatus.pending:
        statusBgColor = kaliColors.sand2;
        statusColor = kaliColors.clayDark;
        break;
      case PaymentStatus.overdue:
        statusBgColor = const Color(0xFFFAEBEB);
        statusColor = const Color(0xFFD4685C);
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          payment.statusLabel,
          style: KaliText.label(statusColor)
              .copyWith(fontSize: 8, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
