import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/entrenadores/create_trainer_dialog.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/bloc/navigation/navigation_bloc.dart';

class AddTrainerButton extends StatefulWidget {
  final int currentTrainerCount;
  final void Function(Map<String, dynamic>) onTrainerCreated;
  const AddTrainerButton({super.key, required this.currentTrainerCount, required this.onTrainerCreated});

  @override
  State<AddTrainerButton> createState() => _AddTrainerButtonState();
}

class _AddTrainerButtonState extends State<AddTrainerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: () async {
          final maxLimit = ProfileCache.maxCoaches;
          if (maxLimit != null && widget.currentTrainerCount >= maxLimit) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Límite de Entrenadores',
                  style: kaliColors.heading(kaliColors.espresso),
                ),
                content: Text(
                  'Tu plan actual permite gestionar hasta $maxLimit entrenador${maxLimit == 1 ? '' : 'es'}. Para sumar más profesionales a tu equipo, mejorá tu plan.',
                  style: kaliColors.body(kaliColors.espresso),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<NavigationBloc>().add(NavigationPageChanged('Suscripción'));
                    },
                    child: const Text('Mejorar Plan'),
                  ),
                ],
              ),
            );
            return;
          }

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
            color: _hovered ? kaliColors.espressoL : kaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 15, color: kaliColors.warmWhite),
              const SizedBox(width: 6),
              Text(
                'Añadir Entrenador',
                style: kaliColors.body(kaliColors.warmWhite,
                    weight: FontWeight.w600, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
