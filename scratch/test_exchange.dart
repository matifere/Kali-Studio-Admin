import 'package:supabase_flutter/supabase_flutter.dart';
void main() {
  SupabaseClient client = SupabaseClient('url', 'anonKey');
  client.auth.exchangeCodeForSession('test');
}
