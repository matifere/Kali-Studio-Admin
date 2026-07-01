import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/kali_text_field.dart';

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

  // ── Panel decorativo izquierdo (solo escritorio) ──────────────────────────
  Widget _buildBrandPanel(KaliColorsExtension kaliColors) {
    return Container(
      color: kaliColors.espresso,
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            "Crear Perfil\nAdministrativo",
            style: KaliText.display(kaliColors.warmWhite).copyWith(
              fontSize: 48,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Comienza a gestionar tu institución\nhoy con herramientas diseñadas\npara la administración profesional.",
            style: KaliText.body(
              kaliColors.clay,
              size: 16,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Formulario de registro ────────────────────────────────────────────────
  Widget _buildForm(BuildContext context, bool isLoading, KaliColorsExtension kaliColors) {
    return Container(
      color: kaliColors.warmWhite,
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Registro de Staff",
              style: KaliText.heading(
                kaliColors.espresso,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Ingresa los detalles para configurar el acceso administrativo al portal del estudio.",
              style: KaliText.body(
                kaliColors.clayDark,
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
              hint: "admin@argrity.com",
              controller: emailControl,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final passField = KaliTextField(
                  label: "CONTRASEÑA",
                  hint: "••••••••",
                  obscureText: _isPassObscured,
                  controller: passControl,
                  suffixIcon: _isPassObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixTap: () => setState(
                    () => _isPassObscured = !_isPassObscured,
                  ),
                );
                final confirmField = KaliTextField(
                  label: "CONFIRMAR CONTRASEÑA",
                  hint: "••••••••",
                  obscureText: _isPassConfirmObscured,
                  controller: passConfirmControl,
                  suffixIcon: _isPassConfirmObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixTap: () => setState(
                    () => _isPassConfirmObscured = !_isPassConfirmObscured,
                  ),
                );
                // En espacios angostos apilamos los campos de contraseña.
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [
                      passField,
                      const SizedBox(height: 20),
                      confirmField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: passField),
                    const SizedBox(width: 16),
                    Expanded(child: confirmField),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleRegister(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kaliColors.espresso,
                  foregroundColor: kaliColors.warmWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: kaliColors.warmWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "CREAR CUENTA",
                        style: KaliText.label(kaliColors.warmWhite).copyWith(
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: RichText(
                  text: TextSpan(
                    style: KaliText.body(
                      kaliColors.clayDark,
                      size: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: "¿Ya eres parte del equipo? ",
                      ),
                      TextSpan(
                        text: "Iniciar Sesión",
                        style: TextStyle(
                          color: kaliColors.espresso,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthSuccess ||
          current is AuthFailure ||
          current is AuthPending,
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.read<AuthBloc>().add(AuthReset());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso')),
          );
          // La navegación a AuthWrapper es manejada por onAuthStateChange en main.dart
        } else if (state is AuthPending) {
          context.read<AuthBloc>().add(AuthReset());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada.'),
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop();
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        // En pantallas anchas mostramos el panel decorativo + formulario lado a
        // lado; en celular, una sola columna con el formulario a ancho completo.
        final bool isWide = MediaQuery.of(context).size.width >= 800;
        return Scaffold(
          backgroundColor: kaliColors.background,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : 460,
                    maxHeight: isWide ? 600 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: kaliColors.warmWhite,
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
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: _buildBrandPanel(kaliColors)),
                            Expanded(
                              flex: 6,
                              child: _buildForm(context, isLoading, kaliColors),
                            ),
                          ],
                        )
                      : _buildForm(context, isLoading, kaliColors),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
