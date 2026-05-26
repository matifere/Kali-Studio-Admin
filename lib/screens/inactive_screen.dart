import 'package:flutter/material.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InactiveScreen extends StatefulWidget {
  const InactiveScreen({super.key});

  @override
  State<InactiveScreen> createState() => _InactiveScreenState();
}

class _InactiveScreenState extends State<InactiveScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (ProfileCache.role == 'sudo') {
      _fetchPlans();
    } else {
      _isLoading = false;
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
        throw Exception("Sesión inválida o institución no encontrada.");
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-saas-subscription',
        body: {
          'institution_id': ProfileCache.institutionId,
          'saas_plan_id': plan['id'],
          'payer_email': user.email,
        },
      );

      final data = response.data;
      if (data != null) {
        // En sandbox (token TEST-...) usar sandbox_init_point. En producción usa init_point.
        final urlString =
            (data['sandbox_init_point'] as String?)?.isNotEmpty == true
                ? data['sandbox_init_point']
                : data['init_point'];
        if (urlString != null) {
          final url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            throw Exception("No se pudo abrir el enlace de pago.");
          }
        } else {
          throw Exception("No se recibió enlace de pago desde el servidor.");
        }
      } else {
        throw Exception("Respuesta vacía del servidor.");
      }
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
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text("Cerrar Sesión"),
        ),
      ],
    );
  }

  Widget _buildSudoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 64,
          color: KaliColors.espresso,
        ),
        Text(
          "Activa tu Institución",
          style: KaliText.heading(KaliColors.espresso),
        ),
        Text(
          "Para comenzar a gestionar tu institución, por favor adquiere una suscripción a Chimpancé.",
          textAlign: TextAlign.center,
          style: KaliText.body(KaliColors.clayDark),
        ),
        const SizedBox(height: 16),
        if (_plans.isEmpty)
          const Text("No hay planes disponibles en este momento.")
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
                        "\$${plan['price']} ${plan['currency']}",
                        style: KaliText.heading(KaliColors.espresso),
                      ),
                      const Text(
                        "por mes",
                        style: TextStyle(color: KaliColors.clayDark),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isProcessing ? null : () => _subscribe(plan),
                          child: const Text("Suscribirse"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text("Cerrar Sesión"),
        ),
      ],
    );
  }
}
