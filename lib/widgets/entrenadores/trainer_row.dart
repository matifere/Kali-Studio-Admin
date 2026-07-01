import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/kali_icon_button.dart';

class TrainerRow extends StatefulWidget {
  final Map<String, dynamic> trainer;
  final VoidCallback onDelete;

  const TrainerRow({super.key, required this.trainer, required this.onDelete});

  @override
  State<TrainerRow> createState() => _TrainerRowState();
}

class _TrainerRowState extends State<TrainerRow> {
  bool _hovered = false;

  String get _initials {
    final name = (widget.trainer['full_name'] as String? ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final name = widget.trainer['full_name'] as String? ?? 'Sin nombre';
    final email = widget.trainer['email'] as String? ?? '—';
    final isActive = widget.trainer['is_active'] as bool? ?? true;
    final statusColor =
        isActive ? const Color(0xFF5C9E6C) : const Color(0xFFD4685C);

    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? kaliColors.warmWhite : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          children: [
            // Nombre + avatar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kaliColors.clay.withValues(alpha: 0.35),
                    child: Text(
                      _initials,
                      style: KaliText.body(
                        kaliColors.espresso,
                        weight: FontWeight.w700,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: KaliText.body(kaliColors.espresso,
                          weight: FontWeight.w600, size: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Correo
            Expanded(
              flex: 4,
              child: Text(
                email,
                style: KaliText.body(
                    kaliColors.espresso.withValues(alpha: 0.55),
                    size: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: KaliText.body(statusColor, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Acciones
            Expanded(
              flex: 2,
              child: KaliIconButton.action(
                Icons.delete_outline,
                tooltip: 'Eliminar',
                color: const Color(0xFFD4685C),
                onTap: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
