import 'package:flutter/material.dart';
import 'package:kali_studio/screens/register_screen.dart';
import 'package:kali_studio/services/auth_service.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';
import 'package:kali_studio/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailControl = TextEditingController();
  final TextEditingController contraControl = TextEditingController();
  bool _isLoading = false;
  bool _isPassObscured = true;

  @override
  void dispose() {
    emailControl.dispose();
    contraControl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (emailControl.text.trim().isEmpty || contraControl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String res = await SupaAuthClass().logInUsuario(
      emailControl.text.trim(),
      contraControl.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res == 'Ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double? widthInForm = 360;
    return Scaffold(
      backgroundColor: KaliColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 48,
          children: [
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
                const SizedBox(
                  height: 16,
                ),
                Text(
                  "Bienvenid@ de nuevo",
                  style: KaliText.loginDisplay(
                    KaliColors.espresso,
                  ),
                ),
                Text(
                  "Accede a tu panel de gestion",
                  style: KaliText.loginBody(KaliColors.espresso),
                )
              ],
            ),
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
                          suffixIcon: Icons.mail),
                      KaliTextField(
                          label: "CONTRASEÑA",
                          hint: "••••••••",
                          actionLabel: "olvide mi contraseña",
                          controller: contraControl,
                          obscureText: _isPassObscured,
                          suffixIcon: _isPassObscured ? Icons.visibility_off : Icons.visibility,
                          onSuffixTap: () {
                            setState(() {
                              _isPassObscured = !_isPassObscured;
                            });
                          },
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: KaliColors.warmWhite,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("ENTRAR")),
                      ),
                      Column(
                        children: [
                          const Row(
                            spacing: 4,
                            children: [
                              Expanded(child: Divider()),
                              Text("o"),
                              Expanded(child: Divider())
                            ],
                          ),
                          Center(
                            child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen()));
                                },
                                child: const Text("Crear Cuenta")),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
