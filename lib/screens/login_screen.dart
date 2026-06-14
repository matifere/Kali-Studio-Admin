import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/screens/register_screen.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/kali_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

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

  Future<void> _handleForgotPassword() async {
    final emailCtrl = TextEditingController(text: emailControl.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Ingresá tu email y te enviamos un link para crear una nueva contraseña.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'tu@email.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://argity.com',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Te enviamos un email a $email con el link para restablecer tu contraseña. Revisá también la carpeta de spam.'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Ocurrió un error inesperado. Intentá nuevamente.')),
        );
      }
    }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 480;
    // El padding de la tarjeta y el del scroll exterior se descuentan del ancho
    // disponible para que el formulario nunca desborde en pantallas angostas.
    final double cardPadding = isSmall ? 24 : 40;
    final double widthInForm =
        (screenWidth - 32 - cardPadding * 2).clamp(0.0, 360.0);
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
          // La navegación real es manejada por onAuthStateChange en main.dart
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo + título ──────────────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/argity_logo.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Bienvenid@ de nuevo",
                        style: KaliText.loginDisplay(KaliColors.espresso),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Accede a tu panel de gestion",
                        style: KaliText.loginBody(KaliColors.espresso),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── Formulario ─────────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                KaliTextField(
                                  label: "CONTRASEÑA",
                                  hint: "••••••••",
                                  controller: contraControl,
                                  obscureText: _isPassObscured,
                                  suffixIcon: _isPassObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  onSuffixTap: () => setState(
                                    () => _isPassObscured = !_isPassObscured,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'olvide mi contraseña',
                                    style:
                                        KaliText.caption(KaliColors.clayDark),
                                  ),
                                ),
                              ],
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
          ),
        );
      },
    );
  }
}
