import 'package:flutter_dotenv/flutter_dotenv.dart';

String getMpRedirectUri() {
  const buildUrl = String.fromEnvironment('SUPABASE_URL');
  final supabaseUrl = buildUrl.isNotEmpty ? buildUrl : (dotenv.env['URL'] ?? 'https://dbturnos.argity.com');
  final cleanUrl = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;
  return '$cleanUrl/functions/v1/mp-auth-callback';
}
