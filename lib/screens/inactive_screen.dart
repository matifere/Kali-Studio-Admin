import 'package:flutter/material.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InactiveScreen extends StatefulWidget {
  const InactiveScreen({super.key});

  @override
  State<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends State<InactiveScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];
  bool _isProcessing = false;
  bool _isVerifying = false;
  bool _hasPendingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ProfileCache.role == 'sudo') {
      _fetchPlans();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Se dispara cuando el usuario vuelve a la app desde el browser externo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasPendingPayment) {
      _verifyAndActivate();
    }
  }

  Future<void> _fetchPlans() async {
    try {
      final data = await Supabase.instance.client
          .from('saas_plans')
          .select('*')
          .eq('is_active', true)
          .order('price', ascending: true);

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    setState(() => _isProcessing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || ProfileCache.institutionId == null) {
        throw Exception('Sesión inválida o institución no encontrada.');
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-saas-subscription',
        body: {
          'institution_id': ProfileCache.institutionId,
          'saas_plan_id': plan['id'],
        },
      );

      final data = response.data;
      if (data == null) throw Exception('Respuesta vacía del servidor.');

      final urlString = data['sandbox_init_point'] ?? data['init_point'];
      if (urlString == null) throw Exception('No se recibió enlace de pago.');

      final url = Uri.parse(urlString as String);
      if (!await canLaunchUrl(url)) throw Exception('No se pudo abrir el enlace de pago.');

      // Marcamos que hay un pago pendiente para verificar al volver
      setState(() => _hasPendingPayment = true);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Consulta directamente Supabase si el perfil ya fue activado,
  // o intenta activarlo via la Edge Function de verificación.
  Future<void> _verifyAndActivate() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Verificar si ya fue activado (el webhook de MP pudo haberlo hecho)
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('is_active')
          .eq('id', user.id)
          .single();

      if (profile['is_active'] == true) {
        _navigateToDashboard();
        return;
      }

      // 2. Si no está activo, buscar si hay un pago approved en tenant_subscriptions
      //    y activar manualmente
      final institutionId = ProfileCache.institutionId;
      if (institutionId == null) return;

      await Supabase.instance.client.functions.invoke(
        'mp-webhook',
        body: {
          'type': 'manual_verify',
          'institution_id': institutionId,
        },
      );

      // 3. Re-verificar tras la activación manual
      await Future.delayed(const Duration(milliseconds: 800));
      final updated = await Supabase.instance.client
          .from('profiles')
          .select('is_active')
          .eq('id', user.id)
          .single();

      if (updated['is_active'] == true) {
        _navigateToDashboard();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El pago aún no fue confirmado. Intentá de nuevo en unos segundos.'),
            ),
          );
        }
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

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: KaliColors.background,
        body: Center(
            child: CircularProgressIndicator(color: KaliColors.espresso)),
      );
    }

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
        const SizedBox(height: 16),
        if (_plans.isEmpty)
          const Text('No hay planes disponibles en este momento.')
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _plans.map((plan) {
              return Card(
                elevation: 0,
                color: KaliColors.warmWhite,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: KaliColors.clayDark, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      Text(
                        plan['name'] ?? '',
                        style: KaliText.heading(KaliColors.espresso),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        plan['description'] ?? '',
                        style: KaliText.caption(KaliColors.clayDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${plan['price']} ${plan['currency']}',
                        style: KaliText.heading(KaliColors.espresso),
                      ),
                      const Text('por mes', style: TextStyle(color: KaliColors.clayDark)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isProcessing ? null : () => _subscribe(plan),
                          child: const Text('Suscribirse'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        // Botón de verificación manual (visible si hay pago pendiente o siempre para sudo)
        if (_hasPendingPayment || true) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isVerifying ? null : _verifyAndActivate,
            icon: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_isVerifying ? 'Verificando...' : 'Ya Pagué — Verificar'),
            style: OutlinedButton.styleFrom(foregroundColor: KaliColors.espresso),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }
}
