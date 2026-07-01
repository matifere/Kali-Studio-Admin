import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/models/subscription.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/avatar_provider.dart';
import 'package:argrity/widgets/common/kali_icon_button.dart';
import 'package:argrity/widgets/pagos/edit_subscription_dialog.dart';

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
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final s = widget.subscription;

    final avatarColors = [kaliColors.clay, kaliColors.sand, kaliColors.sage];
    final avatarColor = avatarColors[s.studentName.length % avatarColors.length];

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
                  if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty && AvatarProvider.fromUrl(s.avatarUrl) != null)
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: avatarColor,
                      backgroundImage: AvatarProvider.fromUrl(s.avatarUrl),
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: avatarColor,
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
                  Expanded(
                    child: Text(
                      s.studentName,
                      style: KaliText.body(
                        KaliColors.espresso,
                        weight: FontWeight.w600,
                        size: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              flex: 2,
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

            // Acciones
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  KaliIconButton.action(
                    Icons.edit_outlined,
                    tooltip: 'Editar asignación',
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<PagosBloc>(),
                        child: EditSubscriptionDialog(subscription: s),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  KaliIconButton.action(
                    Icons.delete_outline_rounded,
                    tooltip: 'Eliminar asignación',
                    color: const Color(0xFFD4685C),
                    onTap: () => _confirmDelete(context, s),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subscription s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar asignación', style: KaliText.heading(KaliColors.espresso, size: 20)),
        content: Text(
          '¿Eliminar el plan "${s.planName}" asignado a ${s.studentName}? '
          'Se borrará también el pago asociado. Esta acción no se puede deshacer.',
          style: KaliText.body(KaliColors.espresso),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFD4685C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PagosBloc>().add(PagosSubscriptionDeleted(s.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asignación de "${s.planName}" eliminada')),
      );
    }
  }
}

// ─── Badge de estado ──────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Subscription subscription;
  const _StatusBadge({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    
    Color statusBgColor;
    Color statusColor;
    switch (subscription.status) {
      case 'active':
        statusBgColor = kaliColors.sageLight;
        statusColor = kaliColors.sage;
        break;
      case 'pending':
        statusBgColor = kaliColors.sand2;
        statusColor = kaliColors.clayDark;
        break;
      case 'expired':
      case 'cancelled':
        statusBgColor = const Color(0xFFFAEBEB);
        statusColor = const Color(0xFFD4685C);
        break;
      default:
        statusBgColor = kaliColors.sand2;
        statusColor = kaliColors.clayDark;
    }

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
            color: statusBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subscription.statusLabel,
                style: KaliText.label(statusColor)
                    .copyWith(fontSize: 8, letterSpacing: 1.0),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 14,
                color: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
