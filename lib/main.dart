import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kali_studio/bloc/auth/auth_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/bloc/navigation/navigation_bloc.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/screens/login_screen.dart';
import 'package:kali_studio/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/kali_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
      url: dotenv.env['URL'] ?? '', anonKey: dotenv.env['ANON'] ?? '');
  runApp(const KaliApp());
}

// ─── KaliApp: crea y posee los BLoCs ─────────────────────────────────────────
//
// Es StatefulWidget para que el ciclo de vida de los BLoCs esté ligado
// al Estado del widget raíz, y no se recreen en cada hot reload / rebuild.
class KaliApp extends StatefulWidget {
  const KaliApp({super.key});

  @override
  State<KaliApp> createState() => _KaliAppState();
}

class _KaliAppState extends State<KaliApp> {
  // Los BLoCs se crean UNA sola vez en initState y se eliminan en dispose.
  // Esto garantiza que hot reload NO los destruya ni duplique eventos.
  late final AuthBloc _authBloc;
  late final NavigationBloc _navigationBloc;
  late final AlumnosBloc _alumnosBloc;
  late final TurnosBloc _turnosBloc;
  late final PagosBloc _pagosBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _navigationBloc = NavigationBloc();
    _alumnosBloc = AlumnosBloc(); // Carga lazy: AlumnosScreen dispara AlumnosLoadRequested en su initState
    _turnosBloc = TurnosBloc();
    _pagosBloc = PagosBloc()..add(PagosLoadRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    _navigationBloc.close();
    _alumnosBloc.close();
    _turnosBloc.close();
    _pagosBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _navigationBloc),
        BlocProvider.value(value: _alumnosBloc),
        BlocProvider.value(value: _turnosBloc),
        BlocProvider.value(value: _pagosBloc),
      ],
      child: const _KaliAppView(),
    );
  }
}

// ─── _KaliAppView: solo UI, sin lógica de creación ───────────────────────────
class _KaliAppView extends StatelessWidget {
  const _KaliAppView();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Kali Studio',
      theme: KaliTheme.theme,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
