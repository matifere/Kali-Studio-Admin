import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kali_studio/bloc/activity/activity_bloc.dart';
import 'package:kali_studio/bloc/auth/auth_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/bloc/navigation/navigation_bloc.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/bloc/dashboard/dashboard_bloc.dart';
import 'package:kali_studio/bloc/notifications/notifications_cubit.dart';
import 'package:kali_studio/screens/login_screen.dart';
import 'package:kali_studio/screens/new_password_screen.dart';
import 'package:kali_studio/widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/kali_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1280, 720),
      size: Size(1280, 720),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final String url;
  final String anon;

  if (kIsWeb) {
    url = 'https://tmfcnvtjzmtpqhzvfxos.supabase.co';
    anon = 'sb_publishable_TkebjBTlimQS7Uu4HWE-tQ_v3ylhC_b';
  } else {
    await dotenv.load(fileName: ".env");
    url = dotenv.env['URL'] ?? '';
    anon = dotenv.env['ANON'] ?? '';
  }

  await initializeDateFormatting('es_ES', null);
  await Supabase.initialize(url: url, anonKey: anon);
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
  late final ActivityBloc _activityBloc;
  late final AlumnosBloc _alumnosBloc;
  late final TurnosBloc _turnosBloc;
  late final PagosBloc _pagosBloc;
  late final DashboardBloc _dashboardBloc;
  late final NotificationsCubit _notificationsCubit;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _navigationBloc = NavigationBloc();
    _activityBloc = ActivityBloc();
    _alumnosBloc = AlumnosBloc(activityBloc: _activityBloc);
    _turnosBloc = TurnosBloc(activityBloc: _activityBloc);
    _pagosBloc = PagosBloc()..add(PagosLoadRequested());
    _dashboardBloc = DashboardBloc();
    _notificationsCubit = NotificationsCubit();
  }

  @override
  void dispose() {
    _authBloc.close();
    _navigationBloc.close();
    _activityBloc.close();
    _alumnosBloc.close();
    _turnosBloc.close();
    _pagosBloc.close();
    _dashboardBloc.close();
    _notificationsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _navigationBloc),
        BlocProvider.value(value: _activityBloc),
        BlocProvider.value(value: _alumnosBloc),
        BlocProvider.value(value: _turnosBloc),
        BlocProvider.value(value: _pagosBloc),
        BlocProvider.value(value: _dashboardBloc),
        BlocProvider.value(value: _notificationsCubit),
      ],
      child: const _KaliAppView(),
    );
  }
}

// ─── _KaliAppView: UI + manejo de recuperación de contraseña ─────────────────
class _KaliAppView extends StatefulWidget {
  const _KaliAppView();

  @override
  State<_KaliAppView> createState() => _KaliAppViewState();
}

class _KaliAppViewState extends State<_KaliAppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;

      // Usar currentUser es más seguro que event.session para evitar
      // race conditions si initialSession llega tarde después de un login rápido.
      final hasSession = Supabase.instance.client.auth.currentUser != null;

      if (event.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
          (route) => false,
        );
      } else if (event.event == AuthChangeEvent.signedOut) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // Forzamos la navegación a la raíz si hubo un evento importante,
        // garantizando que no se dupliquen pantallas en el stack.
        if (event.event == AuthChangeEvent.signedIn ||
            event.event == AuthChangeEvent.initialSession) {
          if (hasSession) {
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          } else if (event.event == AuthChangeEvent.initialSession) {
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold neutro (fondo liso) como estado inicial,
    // toda la navegación la maneja _navigatorKey dinámicamente.
    Widget home = const Scaffold(backgroundColor: KaliColors.warmWhite);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Turnos App',
      theme: KaliTheme.theme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      home: home,
    );
  }
}
