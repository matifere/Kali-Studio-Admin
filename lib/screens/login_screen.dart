import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailControl = TextEditingController();

  final TextEditingController contraControl = TextEditingController();

  LoginScreen({super.key});

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
                          suffixIcon: Icons.visibility_off),
                      FilledButton(
                          onPressed: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 0),
                            child: Center(child: Text("ENTRAR")),
                          )),
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
                                onPressed: () {},
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
