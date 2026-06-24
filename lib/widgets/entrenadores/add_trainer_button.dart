import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/entrenadores/create_trainer_dialog.dart';

class AddTrainerButton extends StatefulWidget {
  final void Function(Map<String, dynamic>) onTrainerCreated;
  const AddTrainerButton({super.key, required this.onTrainerCreated});

  @override
  State<AddTrainerButton> createState() => _AddTrainerButtonState();
}

class _AddTrainerButtonState extends State<AddTrainerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: () async {
          final trainer = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const CreateTrainerDialog(),
          );
          if (trainer != null) widget.onTrainerCreated(trainer);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.espressoL : KaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 15, color: KaliColors.warmWhite),
              const SizedBox(width: 6),
              Text(
                'Añadir Entrenador',
                style: KaliText.body(KaliColors.warmWhite,
                    weight: FontWeight.w600, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
