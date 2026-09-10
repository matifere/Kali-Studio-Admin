import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/alumnos/alumnos_stat_cards.dart';
import 'package:argrity/widgets/alumnos/student_directory.dart';
import 'package:argrity/widgets/alumnos/student_form_dialog.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/bloc/navigation/navigation_bloc.dart';

/// Pantalla de gestión de alumnos.
///
/// Es [StatefulWidget] para poder disparar [AlumnosLoadRequested] exactamente
/// una vez cuando se monta — carga lazy que evita peticiones en background
/// que interfieren con el hot reload de Flutter.
class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  final bool _isProfesor = ProfileCache.isAdmin && !ProfileCache.isSudo;

  @override
  void initState() {
    super.initState();
    context.read<AlumnosBloc>().add(AlumnosLoadRequested());
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
                      AutoSizeText('Alumnos',
                          style: kaliColors
                              .heading(kaliColors.espresso, size: 36)
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1),
                      if (!_isProfesor) ...[
                        const SizedBox(height: 16),
                        const _AddStudentButton(),
                      ],
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
                          AutoSizeText('Alumnos',
                              style: kaliColors
                                  .heading(kaliColors.espresso, size: 46)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1),
                          const SizedBox(height: 4),
                          Text(
                            'Gestiona tu comunidad.',
                            style: kaliColors.body(
                              kaliColors.espresso.withValues(alpha: 0.6),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      if (!_isProfesor) const _AddStudentButton(),
                    ],
                  ),
                const SizedBox(height: 32),
                if (!_isProfesor) ...[
                  const AlumnosStatCards(),
                  const SizedBox(height: 32),
                ],
                const StudentDirectory(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddStudentButton extends StatefulWidget {
  const _AddStudentButton();

  @override
  State<_AddStudentButton> createState() => _AddStudentButtonState();
}

class _AddStudentButtonState extends State<_AddStudentButton> {
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
        child: BlocBuilder<AlumnosBloc, AlumnosState>(
          builder: (context, state) {
            return TextButton.icon(
              onPressed: () {
                if (state is AlumnosLoaded) {
                  final activeCount = state.students.where((s) => s.isActive).length;
                  final maxLimit = ProfileCache.maxStudents;
                  
                  if (maxLimit != null && activeCount >= maxLimit) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Límite de Alumnos Alcanzado',
                          style: kaliColors.heading(kaliColors.espresso),
                        ),
                        content: Text(
                          'Tu plan actual te permite gestionar hasta $maxLimit alumnos activos. Para seguir creciendo, te recomendamos mejorar tu plan.',
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
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const StudentFormDialog(),
                );
              },
              icon: Icon(Icons.add, color: kaliColors.warmWhite, size: 18),
              label: Text(
                'Nuevo Alumno',
                style: kaliColors.body(kaliColors.warmWhite, size: 14)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            );
          },
        ),
      ),
    );
  }
}
