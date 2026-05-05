import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Test enum values', () async {
    await dotenv.load(fileName: ".env");
    final client = SupabaseClient(dotenv.env['URL']!, dotenv.env['ANON']!);
    
    final statuses = ['active', 'pending', 'expired', 'overdue', 'canceled', 'cancelled', 'inactive'];
    
    for (final status in statuses) {
      try {
        await client.from('subscriptions').insert({
          'user_id': '00000000-0000-0000-0000-000000000000',
          'plan_id': '00000000-0000-0000-0000-000000000000',
          'status': status
        });
        print('SUCCESS: $status');
      } catch (e) {
        if (e.toString().contains('invalid input value for enum')) {
          print('INVALID ENUM: $status');
        } else {
          print('VALID ENUM (failed on fkey): $status');
        }
      }
    }
  });
}
