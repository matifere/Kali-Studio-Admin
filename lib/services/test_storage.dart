import 'package:supabase_flutter/supabase_flutter.dart';
void main() {
  final tempClient = SupabaseClient('url', 'anonkey');
  print('compiles fine without localstorage');
}
