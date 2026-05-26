import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InactiveScreen extends StatelessWidget {
  const InactiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: KaliColors.espresso,
              ),
              Text(
                "Cuenta Pendiente",
                style: KaliText.heading(KaliColors.espresso),
              ),
              Text(
                "Tu cuenta ha sido creada y está pendiente de aprobación.\nPor favor, contactá al administrador de tu institución.",
                textAlign: TextAlign.center,
                style: KaliText.body(KaliColors.clayDark),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Supabase.instance.client.auth.signOut();
                },
                child: const Text("Cerrar Sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
