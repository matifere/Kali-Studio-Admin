import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/auth/auth_bloc.dart';
import 'package:kali_studio/screens/register_screen.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';
import 'package:kali_studio/widgets/auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailControl = TextEditingController();
  final TextEditingController contraControl = TextEditingController();
  bool _isPassObscured = true;

  @override
  void dispose() {
    emailControl.dispose();
    contraControl.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (emailControl.text.trim().isEmpty || contraControl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthLoginRequested(
          email: emailControl.text.trim(),
          password: contraControl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    const double widthInForm = 360;
    return BlocConsumer<AuthBloc, AuthState>(
      // El listener solo se activa cuando hay una transición real
      // (no en rebuilds de hot reload con estado previo ya emitido).
      listenWhen: (previous, current) =>
          current is AuthSuccess || current is AuthFailure,
      listener: (context, state) {
        if (state is AuthSuccess) {
          // Reseteamos ANTES de navegar para que si hay un rebuild
          // posterior (hot reload, etc.) el listener no se re-dispare.
          context.read<AuthBloc>().add(AuthReset());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
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
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                // ── Logo + título ──────────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: KaliColors.espresso,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Icon(
                          Icons.self_improvement,
                          color: KaliColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Bienvenid@ de nuevo",
                      style: KaliText.loginDisplay(KaliColors.espresso),
                    ),
                    Text(
                      "Accede a tu panel de gestion",
                      style: KaliText.loginBody(KaliColors.espresso),
                    ),
                  ],
                ),

                // ── Formulario ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(40),
                    child: SizedBox(
                      width: widthInForm,
                      child: Column(
                        spacing: 28,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KaliTextField(
                            label: "EMAIL",
                            hint: "tu@ejemplo.com",
                            controller: emailControl,
                            suffixIcon: Icons.mail,
                          ),
                          KaliTextField(
                            label: "CONTRASEÑA",
                            hint: "••••••••",
                            actionLabel: "olvide mi contraseña",
                            controller: contraControl,
                            obscureText: _isPassObscured,
                            suffixIcon: _isPassObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            onSuffixTap: () => setState(
                              () => _isPassObscured = !_isPassObscured,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _handleLogin(context),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: KaliColors.warmWhite,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("ENTRAR"),
                            ),
                          ),
                          Column(
                            children: [
                              const Row(
                                spacing: 4,
                                children: [
                                  Expanded(child: Divider()),
                                  Text("o"),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text("Crear Cuenta"),
                                ),
                              ),
                            ],
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
      },
    );
  }
}
