import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';
import '../models/models.dart';

// ─── Etiqueta de sección ──────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const SectionLabel(this.text, {super.key,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: KaliText.label(KaliColors.clayDark),
      ),
    );
  }
}

// ─── Fila de clase en listado ─────────────────────────────────────────────────
class ClassListItem extends StatelessWidget {
  final PilatesClass cls;
  final VoidCallback onTap;

  const ClassListItem({super.key, required this.cls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Hora
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cls.time,
                    style: GoogleFontsHelper.cormorant(KaliColors.espresso, 16)),
                  Text(cls.period,
                    style: KaliText.label(KaliColors.clay)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Barra lateral
            Container(
              width: 2, height: 36,
              decoration: BoxDecoration(
                color: cls.isBooked ? KaliColors.clay : KaliColors.sageLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.name,
                    style: KaliText.body(KaliColors.espresso, size: 13)),
                  const SizedBox(height: 2),
                  Text('${cls.instructor} · ${cls.room}',
                    style: KaliText.caption(KaliColors.clayDark)),
                ],
              ),
            ),
            // Badge
            if (cls.isBooked)
              _BookedBadge()
            else
              Text(
                '${cls.availableSpots} ${cls.availableSpots == 1 ? "lugar" : "lugares"}',
                style: KaliText.caption(KaliColors.sage),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: KaliColors.sageLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Reservado',
        style: KaliText.caption(KaliColors.sage)
            .copyWith(fontWeight: FontWeight.w500, fontSize: 10)),
    );
  }
}

// ─── Strip de días de la semana ───────────────────────────────────────────────
class WeekStrip extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDaySelected;

  const WeekStrip({super.key,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  static const nums = ['16', '17', '18', '19', '20', '21'];
  static const hasClass = [false, true, true, true, false, true];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        final isActive = i == widget.selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onDaySelected(i),
            child: Container(
              margin: EdgeInsets.only(right: i < 5 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? KaliColors.espresso : KaliColors.sand2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(days[i],
                    style: KaliText.label(
                      isActive ? KaliColors.clay : KaliColors.clayDark)),
                  const SizedBox(height: 4),
                  Text(nums[i],
                    style: GoogleFontsHelper.cormorant(
                      isActive ? KaliColors.warmWhite : KaliColors.espresso, 17)),
                  if (hasClass[i] && !isActive) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4, height: 4,
                      decoration: const BoxDecoration(
                        color: KaliColors.clay,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ] else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Detalles box grid ────────────────────────────────────────────────────────
class DetailBox extends StatelessWidget {
  final String label;
  final String value;

  const DetailBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KaliColors.sand2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: KaliText.label(KaliColors.clayDark)),
          const SizedBox(height: 4),
          Text(value,
            style: GoogleFontsHelper.cormorant(KaliColors.espresso, 20)),
        ],
      ),
    );
  }
}

// ─── Botón principal ──────────────────────────────────────────────────────────
class KaliButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlined;

  const KaliButton({super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : KaliColors.espresso,
          border: Border.all(
            color: outlined ? KaliColors.espresso : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: KaliText.label(
            outlined ? KaliColors.espresso : KaliColors.clay,
          ).copyWith(fontSize: 12, letterSpacing: 1.8),
        ),
      ),
    );
  }
}

// ─── Helper para Cormorant Garamond ──────────────────────────────────────────
class GoogleFontsHelper {
  static TextStyle cormorant(Color color, double size,
      {bool italic = false, FontWeight weight = FontWeight.w300}) {
    return TextStyle(
      fontFamily: 'Cormorant Garamond',
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
  }
}
