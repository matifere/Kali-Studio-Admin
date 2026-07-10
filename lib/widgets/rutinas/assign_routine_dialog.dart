import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/rutinas/rutinas_bloc.dart';
import 'package:argrity/models/routine.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/rutinas/routine_form_dialog.dart';

/// Diálogo para elegir qué rutina del catálogo asignarle a un alumno.
class AssignRoutineDialog extends StatefulWidget {
  final RoutineStudent student;

  const AssignRoutineDialog({super.key, required this.student});

  @override
  State<AssignRoutineDialog> createState() => _AssignRoutineDialogState();
}

class _AssignRoutineDialogState extends State<AssignRoutineDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _assign(Routine routine) {
    context.read<RutinasBloc>().add(RutinaAssigned(
          userId: widget.student.id,
          routineId: routine.id,
        ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Rutina "${routine.name}" asignada a ${widget.student.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kaliColors.warmWhite,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 560),
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<RutinasBloc, RutinasState>(
          builder: (context, state) {
            final routines = state is RutinasLoaded
                ? state.routines
                    .where((r) =>
                        _query.isEmpty ||
                        r.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList()
                : <Routine>[];
            final assignedId = state is RutinasLoaded
                ? state.assignments[widget.student.id]?.routine.id
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Asignar Rutina',
                        style:
                            kaliColors.heading(kaliColors.espresso, size: 24)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Alumno: ${widget.student.name}',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _query = q),
                  decoration: InputDecoration(
                    hintText: 'Buscar rutina...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: routines.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Todavía no hay rutinas.\nCreá la primera con el botón de abajo.'
                                : 'No se encontraron rutinas',
                            textAlign: TextAlign.center,
                            style: kaliColors.body(
                                kaliColors.espresso.withValues(alpha: 0.65)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: routines.length,
                          separatorBuilder: (_, __) => Divider(
                              color:
                                  kaliColors.espresso.withValues(alpha: 0.1)),
                          itemBuilder: (context, index) {
                            final routine = routines[index];
                            final isCurrent = routine.id == assignedId;
                            return ListTile(
                              leading: Icon(Icons.assignment_outlined,
                                  color: kaliColors.espresso
                                      .withValues(alpha: 0.65)),
                              title: Text(routine.name,
                                  style: kaliColors.body(kaliColors.espresso,
                                      weight: FontWeight.w600)),
                              subtitle: Text(
                                routine.exercises.isNotEmpty
                                    ? '${routine.exercises.length} ejercicios'
                                    : (routine.description ??
                                        'Sin descripción'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: kaliColors.clay, fontSize: 12),
                              ),
                              trailing: isCurrent
                                  ? Text('Asignada',
                                      style: kaliColors.body(
                                          kaliColors.espresso
                                              .withValues(alpha: 0.5),
                                          size: 13))
                                  : TextButton(
                                      onPressed: () => _assign(routine),
                                      child: const Text('Asignar'),
                                    ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => BlocProvider.value(
                        value: context.read<RutinasBloc>(),
                        child: const RoutineFormDialog(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear rutina nueva'),
                  style: TextButton.styleFrom(
                    foregroundColor: kaliColors.espresso,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
