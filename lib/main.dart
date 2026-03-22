import 'package:flutter/material.dart';
import 'theme/kali_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const Scaffold(
        body: Center(child: Text('blanco')),
      ),
    );
  }
}
