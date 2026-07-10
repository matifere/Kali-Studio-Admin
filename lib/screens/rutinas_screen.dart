import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/rutinas/rutinas_bloc.dart';
import 'package:argrity/models/routine.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/avatar_provider.dart';
import 'package:argrity/widgets/rutinas/assign_routine_dialog.dart';
import 'package:argrity/widgets/rutinas/routine_form_dialog.dart';

/// Pantalla de gestión de rutinas: lista todos los alumnos y permite
/// asignarle a cada uno una rutina del catálogo de la institución.
///
/// [StatefulWidget] para disparar [RutinasLoadRequested] una sola vez
/// al montarse, igual que [AlumnosScreen].
class RutinasScreen extends StatefulWidget {
  const RutinasScreen({super.key});

  @override
  State<RutinasScreen> createState() => _RutinasScreenState();
}

class _RutinasScreenState extends State<RutinasScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RutinasBloc>().add(RutinasLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSmall)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText('Rutinas',
                          style: kaliColors
                              .heading(kaliColors.espresso, size: 36)
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1),
                      const SizedBox(height: 16),
                      const _NewRoutineButton(),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText('Rutinas',
                              style: kaliColors
                                  .heading(kaliColors.espresso, size: 46)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1),
                          const SizedBox(height: 4),
                          Text(
                            'Asignale una rutina a cada alumno.',
                            style: kaliColors.body(
                              kaliColors.espresso.withValues(alpha: 0.6),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const _NewRoutineButton(),
                    ],
                  ),
                const SizedBox(height: 32),
                const _StudentRoutineList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botón "Nueva Rutina" ─────────────────────────────────────────────────────
class _NewRoutineButton extends StatefulWidget {
  const _NewRoutineButton();

  @override
  State<_NewRoutineButton> createState() => _NewRoutineButtonState();
}

class _NewRoutineButtonState extends State<_NewRoutineButton> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? kaliColors.espressoL : kaliColors.espresso,
          borderRadius: BorderRadius.circular(28),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: kaliColors.espresso.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: TextButton.icon(
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
          icon: Icon(Icons.add, color: kaliColors.warmWhite, size: 18),
          label: Text(
            'Nueva Rutina',
            style: kaliColors.body(
              kaliColors.warmWhite,
              weight: FontWeight.w600,
              size: 13,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Listado de alumnos con su rutina ────────────────────────────────────────
class _StudentRoutineList extends StatelessWidget {
  const _StudentRoutineList();

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return BlocConsumer<RutinasBloc, RutinasState>(
      listenWhen: (prev, curr) => curr is RutinasError && prev is RutinasLoaded,
      listener: (context, state) {
        if (state is RutinasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      buildWhen: (prev, curr) => curr is! RutinasError || prev is! RutinasLoaded,
      builder: (context, state) {
        if (state is RutinasLoading || state is RutinasInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is RutinasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context
                        .read<RutinasBloc>()
                        .add(RutinasLoadRequested()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state as RutinasLoaded;
        final students = loaded.filteredStudents;

        return Container(
          decoration: BoxDecoration(
            color: kaliColors.sand,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (q) =>
                    context.read<RutinasBloc>().add(RutinasSearchChanged(q)),
                decoration: InputDecoration(
                  hintText: 'Buscar alumno...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: kaliColors.warmWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (students.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No se encontraron alumnos',
                      style: kaliColors
                          .body(kaliColors.espresso.withValues(alpha: 0.65)),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: kaliColors.espresso.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) => _StudentRoutineRow(
                    student: students[index],
                    assignment: loaded.assignments[students[index].id],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentRoutineRow extends StatelessWidget {
  final RoutineStudent student;
  final RoutineAssignment? assignment;

  const _StudentRoutineRow({required this.student, this.assignment});

  void _openAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<RutinasBloc>(),
        child: AssignRoutineDialog(student: student),
      ),
    );
  }

  void _showRoutineDetail(BuildContext context, Routine routine) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kaliColors.warmWhite,
        title: Text(routine.name,
            style: kaliColors.heading(kaliColors.espresso, size: 22)),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (routine.description != null &&
                    routine.description!.isNotEmpty) ...[
                  Text(routine.description!,
                      style: kaliColors.body(
                          kaliColors.espresso.withValues(alpha: 0.75))),
                  const SizedBox(height: 16),
                ],
                if (routine.exercises.isEmpty)
                  Text('Sin ejercicios detallados.',
                      style: kaliColors.body(
                          kaliColors.espresso.withValues(alpha: 0.65)))
                else
                  for (int i = 0; i < routine.exercises.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}.',
                              style: kaliColors.body(kaliColors.clay,
                                  weight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(routine.exercises[i],
                                style:
                                    kaliColors.body(kaliColors.espresso)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar',
                style: kaliColors.body(kaliColors.espresso,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final routine = assignment?.routine;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kaliColors.clay,
            backgroundImage: AvatarProvider.fromUrl(student.avatarUrl),
            child: student.avatarUrl == null
                ? Text(student.initials.toUpperCase(),
                    style:
                        TextStyle(color: kaliColors.warmWhite, fontSize: 12))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: kaliColors.body(
                    kaliColors.espresso
                        .withValues(alpha: student.isActive ? 1.0 : 0.5),
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                routine != null
                    ? InkWell(
                        onTap: () => _showRoutineDetail(context, routine),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 14, color: kaliColors.clayDark),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                routine.name,
                                style: kaliColors.body(kaliColors.clayDark,
                                    size: 13, weight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        'Sin rutina',
                        style: kaliColors.body(
                          kaliColors.espresso.withValues(alpha: 0.5),
                          size: 13,
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (routine == null)
            TextButton(
              onPressed: () => _openAssignDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: kaliColors.espresso,
                backgroundColor: kaliColors.espresso.withValues(alpha: 0.06),
                padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Asignar'),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: kaliColors.espresso.withValues(alpha: 0.65)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: kaliColors.warmWhite,
              onSelected: (value) {
                switch (value) {
                  case 'ver':
                    _showRoutineDetail(context, routine);
                    break;
                  case 'cambiar':
                    _openAssignDialog(context);
                    break;
                  case 'quitar':
                    context
                        .read<RutinasBloc>()
                        .add(RutinaUnassigned(student.id));
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'ver', child: Text('Ver rutina')),
                PopupMenuItem(value: 'cambiar', child: Text('Cambiar rutina')),
                PopupMenuItem(value: 'quitar', child: Text('Quitar rutina')),
              ],
            ),
        ],
      ),
    );
  }
}
