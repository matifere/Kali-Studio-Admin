import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/models/subscription.dart';

class PagosRepository {
  final SupabaseClient _client;

  PagosRepository({required SupabaseClient client}) : _client = client;

  Future<List<Subscription>> getSubscriptions(String? instId) async {
    final response = await _client.from('subscriptions').select(
          'id, user_id, status, start_date, end_date, plan_id, '
          'profiles:profiles!subscriptions_user_id_fkey(id, full_name, avatar_url, institution_id), '
          'plans(id, name, price, currency)',
        );

    final tenantRows = instId != null
        ? response.where((row) {
            final p = row['profiles'];
            if (p is Map) return p['institution_id'] == instId;
            if (p is List && p.isNotEmpty) {
              return p.first['institution_id'] == instId;
            }
            return false;
          }).toList()
        : response;

    return tenantRows
        .map<Subscription>((row) => Subscription.fromJson(row))
        .toList();
  }

  Future<void> markSubscriptionsExpired(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('subscriptions')
        .update({'status': 'expired'})
        .inFilter('id', ids)
        .catchError((_) {});
  }

  Future<void> updateSubscriptionStatus(
      String subscriptionId, String newStatus) async {
    await _client
        .from('subscriptions')
        .update({'status': newStatus}).eq('id', subscriptionId);
  }

  /// Edita la asignación: cambia el plan y/o las fechas de la suscripción y
  /// mantiene el pago asociado en sync con el precio/moneda del nuevo plan.
  Future<void> updateSubscription({
    required String subscriptionId,
    required String planId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _client.from('subscriptions').update({
      'plan_id': planId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    }).eq('id', subscriptionId);

    final plan = await _client
        .from('plans')
        .select('price, currency')
        .eq('id', planId)
        .single();

    await _client.from('payments').update({
      'amount': plan['price'],
      'currency': plan['currency'] ?? 'ARS',
    }).eq('subscription_id', subscriptionId);
  }

  /// Elimina por completo la asignación: borra primero los pagos asociados
  /// (la FK payments.subscription_id no es CASCADE) y luego la suscripción.
  Future<void> deleteSubscription(String subscriptionId) async {
    await _client
        .from('payments')
        .delete()
        .eq('subscription_id', subscriptionId);

    await _client.from('subscriptions').delete().eq('id', subscriptionId);
  }
}
