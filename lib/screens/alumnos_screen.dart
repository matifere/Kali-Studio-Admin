import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/alumnos/alumnos_stat_cards.dart';
import 'package:kali_studio/widgets/alumnos/student_directory.dart';

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
  @override
  void initState() {
    super.initState();
    // Solo carga si el bloc todavía no tiene datos (evita re-fetch al volver).
    final bloc = context.read<AlumnosBloc>();
    if (bloc.state is AlumnosInitial) {
      bloc.add(AlumnosLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Navigation Bar
        const DashboardTopNavBar(),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alumnos',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 46,
                            fontWeight: FontWeight.w600,
                            color: KaliColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestiona tu comunidad de Kali Studio.',
                          style: KaliText.body(
                            KaliColors.espresso.withValues(alpha: 0.6),
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const _AddStudentButton(),
                  ],
                ),
                const SizedBox(height: 32),

                // Stat Cards
                const AlumnosStatCards(),
                const SizedBox(height: 32),

                // Student Directory Table
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? KaliColors.espressoL : KaliColors.espresso,
          borderRadius: BorderRadius.circular(28),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: KaliColors.espresso.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: KaliColors.warmWhite, size: 18),
          label: Text(
            'Añadir Alumno',
            style: KaliText.body(
              KaliColors.warmWhite,
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
