import 'package:flutter/material.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/pagos/saas_subscription_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InactiveScreen extends StatefulWidget {
  const InactiveScreen({super.key});

  @override
  State<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends State<InactiveScreen> {
  @override
  Widget build(BuildContext context) {
    final isSudo = ProfileCache.role == 'sudo';

    return Scaffold(
      backgroundColor: KaliColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: isSudo ? _buildSudoView() : _buildClientView(),
          ),
        ),
      ),
    );
  }

  Widget _buildClientView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        const Icon(Icons.hourglass_empty_rounded,
            size: 80, color: KaliColors.espresso),
        Text('Cuenta Pendiente', style: KaliText.heading(KaliColors.espresso)),
        Text(
          'Tu cuenta ha sido creada y está pendiente de aprobación.\nPor favor, contactá al administrador de tu institución.',
          textAlign: TextAlign.center,
          style: KaliText.body(KaliColors.clayDark),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }

  Widget _buildSudoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        const Icon(Icons.workspace_premium_rounded,
            size: 64, color: KaliColors.espresso),
        Text('Activa tu Institución',
            style: KaliText.heading(KaliColors.espresso)),
        Text(
          'Para comenzar a gestionar tu institución, por favor adquiere una suscripción.',
          textAlign: TextAlign.center,
          style: KaliText.body(KaliColors.clayDark),
        ),
        const SizedBox(height: 24),

        // Reutilizamos el componente completo de suscripciones.
        // La activación ocurre automáticamente vía webhook IPN de Mercado Pago
        // + Supabase Realtime (AuthWrapper detecta el cambio en profiles).
        const SaasSubscriptionView(),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }
}
