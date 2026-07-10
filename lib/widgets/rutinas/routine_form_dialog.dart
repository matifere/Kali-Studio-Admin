import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/rutinas/rutinas_bloc.dart';
import 'package:argrity/data/pilates_exercises.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

/// Diálogo para crear una rutina nueva en el catálogo de la institución.
class RoutineFormDialog extends StatefulWidget {
  const RoutineFormDialog({super.key});

  @override
  State<RoutineFormDialog> createState() => _RoutineFormDialogState();
}

class _RoutineFormDialogState extends State<RoutineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _exerciseControllers = [
    TextEditingController(),
  ];
  int _selectedCategory = 0;

  /// Ejercicios ya cargados (para marcar los sugeridos como agregados).
  Set<String> get _addedExercises =>
      _exerciseControllers.map((c) => c.text.trim()).toSet();

  /// Agrega un ejercicio del catálogo: rellena la última fila si está vacía,
  /// si no crea una fila nueva.
  void _addExercise(String exercise) {
    setState(() {
      final last = _exerciseControllers.last;
      if (last.text.trim().isEmpty) {
        last.text = exercise;
      } else {
        _exerciseControllers.add(TextEditingController(text: exercise));
      }
    });
  }

  /// Agrega la serie completa de la categoría seleccionada (sin duplicar).
  void _addFullSeries() {
    final added = _addedExercises;
    for (final exercise in pilatesCatalog[_selectedCategory].exercises) {
      if (!added.contains(exercise)) _addExercise(exercise);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _exerciseControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final exercises = _exerciseControllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    context.read<RutinasBloc>().add(RutinaCreated(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          exercises: exercises,
        ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rutina creada correctamente')),
    );
  }

  InputDecoration _decoration(KaliColorsExtension kaliColors, String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: kaliColors.espresso.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: kaliColors.espresso.withValues(alpha: 0.1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kaliColors.warmWhite,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nueva Rutina',
                      style: kaliColors.heading(kaliColors.espresso, size: 24)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _decoration(
                            kaliColors, 'Nombre (ej. Principiante A)'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration:
                            _decoration(kaliColors, 'Descripción (opcional)'),
                      ),
                      const SizedBox(height: 20),
                      Text('Ejercicios',
                          style: kaliColors.body(kaliColors.espresso,
                              size: 14, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _exerciseControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _exerciseControllers[i],
                                  decoration: _decoration(kaliColors,
                                      'Ejercicio ${i + 1} (ej. El Cien · 100 bombeos)'),
                                ),
                              ),
                              if (_exerciseControllers.length > 1)
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      color: kaliColors.espresso
                                          .withValues(alpha: 0.65)),
                                  onPressed: () => setState(() {
                                    _exerciseControllers
                                        .removeAt(i)
                                        .dispose();
                                  }),
                                ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _exerciseControllers.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar ejercicio'),
                        style: TextButton.styleFrom(
                          foregroundColor: kaliColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catálogo de ejercicios',
                              style: kaliColors.body(kaliColors.espresso,
                                  size: 14, weight: FontWeight.w600)),
                          TextButton(
                            onPressed: _addFullSeries,
                            style: TextButton.styleFrom(
                              foregroundColor: kaliColors.espresso,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Agregar serie completa',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < pilatesCatalog.length; i++)
                            ChoiceChip(
                              label: Text(pilatesCatalog[i].name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedCategory == i
                                          ? kaliColors.warmWhite
                                          : kaliColors.espresso)),
                              selected: _selectedCategory == i,
                              selectedColor: kaliColors.espresso,
                              backgroundColor: kaliColors.espresso
                                  .withValues(alpha: 0.06),
                              showCheckmark: false,
                              side: BorderSide.none,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final exercise
                              in pilatesCatalog[_selectedCategory].exercises)
                            _addedExercises.contains(exercise)
                                ? Chip(
                                    label: Text(exercise,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: kaliColors.espresso
                                                .withValues(alpha: 0.4))),
                                    avatar: Icon(Icons.check,
                                        size: 14,
                                        color: kaliColors.espresso
                                            .withValues(alpha: 0.4)),
                                    backgroundColor: kaliColors.espresso
                                        .withValues(alpha: 0.04),
                                    side: BorderSide.none,
                                  )
                                : ActionChip(
                                    label: Text(exercise,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: kaliColors.espresso)),
                                    avatar: Icon(Icons.add,
                                        size: 14, color: kaliColors.espresso),
                                    backgroundColor: kaliColors.warmWhite,
                                    side: BorderSide(
                                        color: kaliColors.espresso
                                            .withValues(alpha: 0.15)),
                                    onPressed: () => _addExercise(exercise),
                                  ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: kaliColors
                            .body(kaliColors.espresso.withValues(alpha: 0.6))),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submit,
                    style: TextButton.styleFrom(
                      backgroundColor: kaliColors.espresso,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text('Crear Rutina',
                        style: kaliColors.body(kaliColors.warmWhite,
                            weight: FontWeight.w600, size: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
