import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Botón de ícono reutilizable con tooltip.
///
/// Parametrizable en tamaño y padding para cubrir variantes como
/// botones de acción en tablas (pequeños) o botones de toolbar (medianos).
class KaliIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double iconSize;
  final double padding;
  final Color? color;

  const KaliIconButton(
    this.icon, {
    super.key,
    required this.tooltip,
    this.onTap,
    this.iconSize = 20,
    this.padding = 8,
    this.color,
  });

  /// Variante pequeña para acciones dentro de filas de tabla.
  const KaliIconButton.action(
    this.icon, {
    super.key,
    required this.tooltip,
    this.onTap,
    this.iconSize = 16,
    this.padding = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? () {},
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? KaliColors.espresso.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
