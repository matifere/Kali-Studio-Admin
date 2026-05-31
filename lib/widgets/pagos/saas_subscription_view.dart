import 'package:flutter/material.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SaasSubscriptionView extends StatefulWidget {
  const SaasSubscriptionView({super.key});

  @override
  State<SaasSubscriptionView> createState() => _SaasSubscriptionViewState();
}

class _SaasSubscriptionViewState extends State<SaasSubscriptionView> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final institutionId = ProfileCache.institutionId;
      if (institutionId == null) throw Exception('No hay institución.');

      // 1. Fetch de los planes SaaS disponibles
      final plansData = await Supabase.instance.client
          .from('saas_plans')
          .select('*')
          .eq('is_active', true)
          .order('price', ascending: true);

      // 2. Fetch de la suscripción actual de la institución
      final subData = await Supabase.instance.client
          .from('tenant_subscriptions')
          .select('*, saas_plans(*)')
          .eq('institution_id', institutionId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(plansData);
          _currentSubscription = subData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    setState(() => _isProcessing = true);
    try {
      final institutionId = ProfileCache.institutionId;
      if (institutionId == null) {
        throw Exception('Institución no encontrada.');
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-saas-subscription',
        body: {
          'institution_id': institutionId,
          'saas_plan_id': plan['id'],
        },
      );

      final data = response.data;
      if (data == null) throw Exception('Respuesta vacía del servidor.');

      final urlString = data['sandbox_init_point'] ?? data['init_point'];
      if (urlString == null) throw Exception('No se recibió enlace de pago.');

      final url = Uri.parse(urlString as String);
      if (!await canLaunchUrl(url)) throw Exception('No se pudo abrir el enlace de pago.');

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KaliColors.espresso),
      );
    }

    final currentPlanName = _currentSubscription != null && _currentSubscription!['saas_plans'] != null
        ? _currentSubscription!['saas_plans']['name']
        : 'Ninguno';
    final currentStatus = _currentSubscription != null ? _currentSubscription!['status'] : 'Sin suscripción';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de estado actual
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: KaliColors.warmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KaliColors.clayDark, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suscripción Actual',
                style: KaliText.heading(KaliColors.espresso, size: 24),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBadge('Plan', currentPlanName),
                  const SizedBox(width: 16),
                  _buildInfoBadge('Estado', _translateStatus(currentStatus)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        Text(
          'Planes Disponibles',
          style: KaliText.heading(KaliColors.espresso, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Mejora tu plan para acceder a nuevas herramientas de gestión y soporte.',
          style: KaliText.body(KaliColors.clayDark, size: 14),
        ),
        const SizedBox(height: 24),

        if (_plans.isEmpty)
          Text('No hay planes disponibles en este momento.', style: KaliText.body(KaliColors.espresso))
        else
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: _plans.map((plan) {
              final isCurrent = _currentSubscription?['saas_plan_id'] == plan['id'];
              return _buildPlanCard(plan, isCurrent);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KaliText.caption(KaliColors.clayDark)),
          const SizedBox(height: 4),
          Text(value, style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isCurrent) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isCurrent ? KaliColors.espresso : KaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? KaliColors.espresso : KaliColors.clayDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCurrent ? 0.1 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: KaliColors.clay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PLAN ACTUAL',
                style: KaliText.caption(KaliColors.espresso).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          Text(
            plan['name'] ?? '',
            style: KaliText.heading(isCurrent ? KaliColors.warmWhite : KaliColors.espresso, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            plan['description'] ?? '',
            style: KaliText.body(isCurrent ? KaliColors.sand : KaliColors.clayDark, size: 14),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${plan['price']}',
                style: KaliText.heading(isCurrent ? KaliColors.warmWhite : KaliColors.espresso, size: 40),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                child: Text(
                  '${plan['currency']}/mes',
                  style: KaliText.body(isCurrent ? KaliColors.sand : KaliColors.clayDark, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_isProcessing || isCurrent) ? null : () => _subscribe(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? KaliColors.warmWhite : KaliColors.espresso,
                foregroundColor: isCurrent ? KaliColors.espresso : KaliColors.warmWhite,
                disabledBackgroundColor: isCurrent ? KaliColors.warmWhite.withValues(alpha: 0.5) : null,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: isCurrent ? KaliColors.espresso : KaliColors.warmWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isCurrent ? 'ACTIVO' : 'SUSCRIBIRSE',
                      style: KaliText.label(
                        isCurrent ? KaliColors.espresso : KaliColors.warmWhite,
                      ).copyWith(letterSpacing: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'active':
      case 'authorized':
        return 'Activo';
      case 'pending':
        return 'Pendiente';
      case 'paused':
        return 'Pausado';
      case 'cancelled':
        return 'Cancelado';
      case 'expired':
        return 'Vencido';
      default:
        return status;
    }
  }
}
