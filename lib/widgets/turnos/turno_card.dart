import 'package:flutter/material.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/models/turno.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Tarjeta visual de un turno dentro del calendario semanal.
///
/// El alto se calcula proporcionalmente a la duración del turno.
/// El color depende del [TurnoType].
class TurnoCard extends StatefulWidget {
  final ClassSession turno;
  final VoidCallback? onTap;
  final bool isCompactMode;

  const TurnoCard({super.key, required this.turno, this.onTap, this.isCompactMode = false});

  @override
  State<TurnoCard> createState() => _TurnoCardState();
}

class _TurnoCardState extends State<TurnoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.turno;
    final bg = t.backgroundColor;
    final fg = t.foregroundColor;
    final isPrivate = t.uiTurnoType == TurnoType.privateSpecial;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(widget.isCompactMode ? 6 : 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: _hovered
                ? Border.all(
                    color: isPrivate
                        ? KaliColors.clay
                        : KaliColors.espresso.withValues(alpha: 0.2),
                    width: 1.5,
                  )
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: widget.isCompactMode ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              // Parte superior: nombre + instructor
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: KaliText.label(fg.withValues(alpha: widget.isCompactMode ? 0.9 : 0.7)).copyWith(
                      fontSize: widget.isCompactMode ? 12 : null,
                      fontWeight: widget.isCompactMode ? FontWeight.bold : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isCompactMode) ...[
                    const SizedBox(height: 3),
                    Text(
                      t.instructorName ?? 'Sin instructor',
                      style: KaliText.body(fg, weight: FontWeight.w600, size: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),

              // Parte inferior: ocupación
              if (!widget.isCompactMode)
                Row(
                  children: [
                    Text(
                      t.occupancyText,
                      style: KaliText.label(
                        fg.withValues(alpha: t.isFull ? 0.9 : 0.55),
                      ),
                    ),
                    if (t.isFull) ...[
                      const SizedBox(width: 4),
                      Text(
                        'full',
                        style: KaliText.label(fg.withValues(alpha: 0.55)),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
