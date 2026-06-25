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
}
