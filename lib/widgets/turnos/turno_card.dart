import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/models/class_session.dart';
import 'package:argrity/models/turno.dart';
import 'package:argrity/theme/kali_theme.dart';

/// Tarjeta visual de un turno dentro del calendario semanal.
///
/// El alto se calcula proporcionalmente a la duración del turno.
/// El color depende del [TurnoType].
class TurnoCard extends StatefulWidget {
  final ClassSession turno;
  final VoidCallback? onTap;

  const TurnoCard({super.key, required this.turno, this.onTap});

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
      onEnter: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true); },
      onExit: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          clipBehavior: Clip.hardEdge,
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
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final h = constraints.maxHeight;
              if (h < 14) return const SizedBox.shrink();
              final vPad = h < 22 ? 2.0 : 6.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: vPad),
                child: Text(
                  t.name,
                  style: KaliText.label(fg.withValues(alpha: 0.9)).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
