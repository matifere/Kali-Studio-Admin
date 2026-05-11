import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/auth/auth_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';
import 'package:kali_studio/widgets/auth_wrapper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameControl = TextEditingController();
  final TextEditingController emailControl = TextEditingController();
  final TextEditingController passControl = TextEditingController();
  final TextEditingController passConfirmControl = TextEditingController();
  bool _isPassObscured = true;
  bool _isPassConfirmObscured = true;

  @override
  void dispose() {
    nameControl.dispose();
    emailControl.dispose();
    passControl.dispose();
    passConfirmControl.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    if (nameControl.text.trim().isEmpty ||
        emailControl.text.trim().isEmpty ||
        passControl.text.isEmpty ||
        passConfirmControl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }
    if (passControl.text != passConfirmControl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterRequested(
          email: emailControl.text.trim(),
          password: passControl.text,
          fullName: nameControl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthSuccess || current is AuthFailure,
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.read<AuthBloc>().add(AuthReset());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: KaliColors.background,
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        width: 900,
                        height: 600,
                        decoration: BoxDecoration(
                          color: KaliColors.warmWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Panel izquierdo ────────────────────────────
                            Expanded(
                              flex: 4,
                              child: Container(
                                color: KaliColors.espresso,
                                padding: const EdgeInsets.all(48.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      "Crear Perfil\nAdministrativo",
                                      style:
                                          KaliText.display(KaliColors.warmWhite)
                                              .copyWith(
                                        fontSize: 48,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      "Comienza a gestionar tu institución\nhoy con herramientas diseñadas\npara la administración profesional.",
                                      style: KaliText.body(
                                        KaliColors.clay,
                                        size: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),

                            // ── Panel derecho (formulario) ─────────────────
                            Expanded(
                              flex: 6,
                              child: Container(
                                color: KaliColors.warmWhite,
                                padding: const EdgeInsets.all(48.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Registro de Staff",
                                        style: KaliText.heading(
                                          KaliColors.espresso,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Ingresa los detalles para configurar el acceso administrativo al portal del estudio.",
                                        style: KaliText.body(
                                          KaliColors.clayDark,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      KaliTextField(
                                        label: "NOMBRE COMPLETO",
                                        hint: "Ej. Alejandra Rossi",
                                        controller: nameControl,
                                      ),
                                      const SizedBox(height: 20),
                                      KaliTextField(
                                        label: "EMAIL DE TRABAJO",
                                        hint: "admin@kali-studio.com",
                                        controller: emailControl,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: KaliTextField(
                                              label: "CONTRASEÑA",
                                              hint: "••••••••",
                                              obscureText: _isPassObscured,
                                              controller: passControl,
                                              suffixIcon: _isPassObscured
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              onSuffixTap: () => setState(
                                                () => _isPassObscured =
                                                    !_isPassObscured,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: KaliTextField(
                                              label: "CONFIRMAR CONTRASEÑA",
                                              hint: "••••••••",
                                              obscureText:
                                                  _isPassConfirmObscured,
                                              controller: passConfirmControl,
                                              suffixIcon: _isPassConfirmObscured
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              onSuffixTap: () => setState(
                                                () => _isPassConfirmObscured =
                                                    !_isPassConfirmObscured,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => _handleRegister(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                KaliColors.espresso,
                                            foregroundColor:
                                                KaliColors.warmWhite,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(27),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: KaliColors.warmWhite,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  "CREAR CUENTA",
                                                  style: KaliText.label(
                                                          KaliColors.warmWhite)
                                                      .copyWith(
                                                    fontSize: 12,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Center(
                                        child: InkWell(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: RichText(
                                            text: TextSpan(
                                              style: KaliText.body(
                                                KaliColors.clayDark,
                                                size: 14,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text:
                                                      "¿Ya eres parte del equipo? ",
                                                ),
                                                TextSpan(
                                                  text: "Iniciar Sesión",
                                                  style: TextStyle(
                                                    color: KaliColors.espresso,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
