import 'package:flutter/material.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/pagos/saas_subscription_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InactiveScreen extends StatefulWidget {
  const InactiveScreen({super.key});

  @override
  State<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends State<InactiveScreen> {
  bool _isVerifying = false;

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
        const Icon(Icons.hourglass_empty_rounded, size: 80, color: KaliColors.espresso),
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
        const Icon(Icons.workspace_premium_rounded, size: 64, color: KaliColors.espresso),
        Text('Activa tu Institución', style: KaliText.heading(KaliColors.espresso)),
        Text(
          'Para comenzar a gestionar tu institución, por favor adquiere una suscripción a Chimpancé.',
          textAlign: TextAlign.center,
          style: KaliText.body(KaliColors.clayDark),
        ),
        const SizedBox(height: 24),
        
        // Reutilizamos el componente completo de suscripciones
        const SaasSubscriptionView(),

        const SizedBox(height: 16),
        
        // Botón de verificación manual por si acaso
        OutlinedButton.icon(
          onPressed: _isVerifying ? null : _verifyAndActivate,
          icon: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_isVerifying ? 'Verificando...' : 'Forzar Verificación de Pago'),
          style: OutlinedButton.styleFrom(foregroundColor: KaliColors.espresso),
        ),
        
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }

  Future<void> _verifyAndActivate() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final institutionId = ProfileCache.institutionId;
      if (user == null || institutionId == null) return;

      await Supabase.instance.client.functions.invoke(
        'mp-webhook',
        body: {
          'type': 'manual_verify',
          'institution_id': institutionId,
        },
      );

      // No necesitamos re-verificar y hacer push a Dashboard aquí,
      // porque AuthWrapper está escuchando cambios en realtime en 'profiles'.
      // Si el webhook activó la cuenta, AuthWrapper lo detectará instantáneamente
      // y cambiará la pantalla por sí mismo.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobación enviada. Si el pago ingresó, serás redirigido en breve.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }
}
