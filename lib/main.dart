import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kali_studio/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/kali_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
      url: dotenv.env['URL'] ?? '', anonKey: dotenv.env['ANON'] ?? '');
  runApp(const KaliApp());
}

class KaliApp extends StatelessWidget {
  const KaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kali Studio',
      theme: KaliTheme.theme,
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
