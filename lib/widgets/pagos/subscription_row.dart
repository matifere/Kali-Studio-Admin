import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/models/subscription.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/avatar_provider.dart';

/// Fila de la tabla de suscripciones.
class SubscriptionRow extends StatefulWidget {
  final Subscription subscription;
  const SubscriptionRow({super.key, required this.subscription});

  @override
  State<SubscriptionRow> createState() => _SubscriptionRowState();
}

class _SubscriptionRowState extends State<SubscriptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;

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
                  if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty && AvatarProvider.fromUrl(s.avatarUrl) != null)
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: s.avatarColor,
                      backgroundImage: AvatarProvider.fromUrl(s.avatarUrl),
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: s.avatarColor,
                      child: Text(
                        s.studentInitials,
                        style: KaliText.body(
                          KaliColors.espresso,
                          weight: FontWeight.w700,
                          size: 11,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    s.studentName,
                    style: KaliText.body(
                      KaliColors.espresso,
                      weight: FontWeight.w600,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Plan
            Expanded(
              flex: 3,
              child: Text(
                s.planName,
                style: KaliText.body(
                  KaliColors.espresso.withValues(alpha: 0.8),
                  size: 13,
                  weight: FontWeight.w500,
                ),
              ),
            ),

            // Fechas
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.startDateFormatted,
                    style: KaliText.body(
                      KaliColors.espresso.withValues(alpha: 0.6),
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.endDateFormatted,
                    style: KaliText.body(
                      KaliColors.espresso.withValues(alpha: 0.45),
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: _StatusBadge(subscription: s),
            ),

            // Monto (Precio del Plan)
            Expanded(
              flex: 2,
              child: Text(
                s.amountFormatted,
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
  final Subscription subscription;
  const _StatusBadge({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: 'Cambiar estado',
        offset: const Offset(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (newStatus) {
          if (newStatus != subscription.status) {
            context.read<PagosBloc>().add(
                  PagosSubscriptionStatusChanged(
                    subscriptionId: subscription.id,
                    newStatus: newStatus,
                  ),
                );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'active', child: Text('Activo')),
          PopupMenuItem(value: 'pending', child: Text('Pendiente')),
          PopupMenuItem(value: 'expired', child: Text('Vencido')),
          PopupMenuItem(value: 'cancelled', child: Text('Cancelado')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: subscription.statusBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subscription.statusLabel,
                style: KaliText.label(subscription.statusColor)
                    .copyWith(fontSize: 8, letterSpacing: 1.0),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 14,
                color: subscription.statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
