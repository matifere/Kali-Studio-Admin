import 'package:flutter/material.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';
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
  RealtimeChannel? _subscriptionChannel;

  @override
  void initState() {
    super.initState();
    _fetchData().then((_) {
      _setupRealtime();
    });
  }

  @override
  void dispose() {
    final channel = _subscriptionChannel;
    if (channel != null) {
      // Usar microtask previene un deadlock interno de supabase_flutter 
      // si dispose() es llamado como resultado de un evento realtime concurrente.
      Future.microtask(() => channel.unsubscribe());
    }
    super.dispose();
  }

  void _setupRealtime() {
    final institutionId = ProfileCache.institutionId;
    if (institutionId == null) return;

    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    _subscriptionChannel = Supabase.instance.client
        .channel('public:tenant_subscriptions_$uniqueId')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tenant_subscriptions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'institution_id',
              value: institutionId,
            ),
            callback: (payload) {
              if (mounted) {
                _fetchData(); // Volvemos a hacer fetch para traer los joins actualizados
              }
            })
        .subscribe();
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
          const SnackBar(content: Text('No se pudieron cargar los datos. Intentá nuevamente.')),
        );
      }
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    if (_isProcessing) return;
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
      
      // Si el servidor devolvió un error (aunque tenga status 200)
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }

      final urlString = data['sandbox_init_point'] ?? data['init_point'];
      if (urlString == null) throw Exception('No se recibió enlace de pago. Data: $data');

      final url = Uri.parse(urlString.toString());
      if (!await canLaunchUrl(url)) throw Exception('No se pudo abrir el enlace de pago.');

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } on FunctionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${e.details ?? e.reasonPhrase ?? "Desconocido"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar suscripción?'),
        content: const Text(
            'Tu suscripción no se renovará el próximo mes. Podrás seguir usando la aplicación hasta que finalice el ciclo de facturación actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final institutionId = ProfileCache.institutionId;
      if (institutionId == null) throw Exception('No hay institución');

      final response = await Supabase.instance.client.functions.invoke(
        'cancel-saas-subscription',
        body: {'institution_id': institutionId},
      );

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Error desconocido al cancelar.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suscripción cancelada exitosamente.')),
        );
        // Volvemos a cargar las suscripciones para reflejar el estado 'cancelled'
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado. Intentá nuevamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildInfoBadge('Plan', currentPlanName),
                      const SizedBox(width: 16),
                      _buildInfoBadge('Estado', _translateStatus(currentStatus)),
                    ],
                  ),
                  if (currentStatus == 'active' || currentStatus == 'authorized')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: _cancelSubscription,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar Suscripción'),
                    ),
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
              final matchesPlanId = _currentSubscription?['saas_plan_id'] == plan['id'];
              final status = _currentSubscription?['status'];
              final isActive = status == 'active' || status == 'authorized';
              final isPending = status == 'pending';
              
              final isCurrent = matchesPlanId && isActive;
              final isThisPlanPending = matchesPlanId && isPending;

              return _buildPlanCard(plan, isCurrent, isThisPlanPending);
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

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isCurrent, bool isThisPlanPending) {
    final highlight = isCurrent || isThisPlanPending;
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: highlight ? KaliColors.espresso : KaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? KaliColors.espresso : KaliColors.clayDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlight ? 0.1 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? KaliColors.clay : Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCurrent ? 'PLAN ACTUAL' : 'PAGO PENDIENTE',
                style: KaliText.caption(KaliColors.espresso).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          Text(
            plan['name'] ?? '',
            style: KaliText.heading(highlight ? KaliColors.warmWhite : KaliColors.espresso, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            plan['description'] ?? '',
            style: KaliText.body(highlight ? KaliColors.sand : KaliColors.clayDark, size: 14),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${plan['price']}',
                style: KaliText.heading(highlight ? KaliColors.warmWhite : KaliColors.espresso, size: 40),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                child: Text(
                  '${plan['currency']}/${(plan['interval'] == 'year' || plan['billing_cycle'] == 'yearly' || (plan['name'] ?? '').toString().toLowerCase().contains('anual')) ? 'año' : 'mes'}',
                  style: KaliText.body(highlight ? KaliColors.sand : KaliColors.clayDark, size: 14),
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
                backgroundColor: highlight ? KaliColors.warmWhite : KaliColors.espresso,
                foregroundColor: highlight ? KaliColors.espresso : KaliColors.warmWhite,
                disabledBackgroundColor: highlight ? KaliColors.warmWhite.withValues(alpha: 0.5) : null,
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
                        color: highlight ? KaliColors.espresso : KaliColors.warmWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isCurrent 
                        ? 'ACTIVO' 
                        : (isThisPlanPending ? 'REINTENTAR PAGO' : 'SUSCRIBIRSE'),
                      style: KaliText.label(
                        highlight ? KaliColors.espresso : KaliColors.warmWhite,
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
