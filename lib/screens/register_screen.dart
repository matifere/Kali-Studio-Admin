import 'package:flutter/material.dart';
import 'package:kali_studio/services/auth_service.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    nameControl.dispose();
    emailControl.dispose();
    passControl.dispose();
    passConfirmControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Panel
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
                                  style: KaliText.display(KaliColors.warmWhite)
                                      .copyWith(
                                          fontSize: 48,
                                          fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "Comienza a gestionar el estudio\nhoy con herramientas diseñadas\npara la administración profesional.",
                                  style:
                                      KaliText.body(KaliColors.clay, size: 16),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                        // Right Panel
                        Expanded(
                          flex: 6,
                          child: Container(
                            color: KaliColors.warmWhite,
                            padding: const EdgeInsets.all(48.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Registro de Staff",
                                      style: KaliText.heading(
                                          KaliColors.espresso,
                                          size: 32)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Ingresa los detalles para configurar el acceso administrativo al portal del estudio.",
                                    style: KaliText.body(KaliColors.clayDark,
                                        size: 14),
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
                                          onSuffixTap: () {
                                            setState(() {
                                              _isPassObscured =
                                                  !_isPassObscured;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: KaliTextField(
                                          label: "CONFIRMAR CONTRASEÑA",
                                          hint: "••••••••",
                                          obscureText: _isPassConfirmObscured,
                                          controller: passConfirmControl,
                                          suffixIcon: _isPassConfirmObscured
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          onSuffixTap: () {
                                            setState(() {
                                              _isPassConfirmObscured =
                                                  !_isPassConfirmObscured;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (nameControl.text
                                                      .trim()
                                                      .isEmpty ||
                                                  emailControl.text
                                                      .trim()
                                                      .isEmpty ||
                                                  passControl.text.isEmpty ||
                                                  passConfirmControl
                                                      .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Por favor llena todos los campos')));
                                                return;
                                              }
                                              if (passControl.text !=
                                                  passConfirmControl.text) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Las contraseñas no coinciden')));
                                                return;
                                              }

                                              setState(() {
                                                _isLoading = true;
                                              });
                                              String res = await SupaAuthClass()
                                                  .registrarUsuario(
                                                emailControl.text.trim(),
                                                passControl.text,
                                                nameControl.text.trim(),
                                              );
                                              if (!mounted) {
                                                return;
                                              }
                                              setState(() {
                                                _isLoading = false;
                                              });
                                              if (res == 'Ok') {
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Registro exitoso')));
                                                // ignore: use_build_context_synchronously
                                                Navigator.of(context).pop();
                                              } else {
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(res)));
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: KaliColors.espresso,
                                        foregroundColor: KaliColors.warmWhite,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(27),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
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
                                                      letterSpacing: 2),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Center(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: KaliText.body(
                                              KaliColors.clayDark,
                                              size: 14),
                                          children: const [
                                            TextSpan(
                                                text:
                                                    "¿Ya eres parte del equipo? "),
                                            TextSpan(
                                              text: "Iniciar Sesión",
                                              style: TextStyle(
                                                  color: KaliColors.espresso,
                                                  fontWeight: FontWeight.bold),
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
          // Footer
        ],
      ),
    );
  }
}
