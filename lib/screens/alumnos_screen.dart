import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/alumnos/alumnos_stat_cards.dart';
import 'package:kali_studio/widgets/alumnos/student_directory.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';
import 'package:kali_studio/services/auth_service.dart';
import 'package:kali_studio/services/profile_cache.dart';

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
  final bool _isProfesor = ProfileCache.isAdmin;

  @override
  void initState() {
    super.initState();
    context.read<AlumnosBloc>().add(AlumnosLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSmall)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alumnos',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: KaliColors.espresso,
                        ),
                      ),
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
                            'Gestiona tu comunidad de Chimpance Admin.',
                            style: KaliText.body(
                              KaliColors.espresso.withValues(alpha: 0.6),
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
    return MouseRegion(
      onEnter: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true); },
      onExit: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false); },
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
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const _AddStudentDialog(),
            );
          },
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

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Revisa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = SupaAuthClass();
    final result = await authService.registrarAlumno(email, pass, name);

    if (result == 'Ok') {
      if (mounted) {
        final bloc = context.read<AlumnosBloc>();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        bloc.add(AlumnosLoadRequested());
        messenger.showSnackBar(
          SnackBar(
            content: Text('Alumno "$name" registrado correctamente.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: KaliColors.warmWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Añadir Nuevo Alumno',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se registrará con rol de usuario cliente.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 32),
                KaliTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  hint: 'Ej. María Pérez',
                ),
                const SizedBox(height: 16),
                KaliTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  hint: 'correo@ejemplo.com',
                ),
                const SizedBox(height: 16),
                KaliTextField(
                  controller: _passwordController,
                  label: 'Contraseña temporal',
                  hint: 'Mínimo 6 caracteres',
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: KaliText.body(const Color(0xFFD4685C)),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: KaliText.body(KaliColors.espresso),
                      ),
                    ),
                    const SizedBox(width: 16),
                    MouseRegion(
                      cursor: _isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: _isLoading ? KaliColors.espresso.withValues(alpha: 0.6) : KaliColors.espresso,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: KaliColors.warmWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Registrar Alumno',
                                  style: KaliText.body(KaliColors.warmWhite, weight: FontWeight.w600, size: 13),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
