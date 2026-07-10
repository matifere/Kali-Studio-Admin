import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'package:argrity/bloc/activity/activity_bloc.dart';
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';
import 'package:argrity/bloc/navigation/navigation_bloc.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/bloc/dashboard/dashboard_bloc.dart';
import 'package:argrity/bloc/notifications/notifications_cubit.dart';
import 'package:argrity/screens/login_screen.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/services/auth_service.dart';
import 'package:argrity/screens/new_password_screen.dart';
import 'package:argrity/widgets/auth_wrapper.dart';
import 'package:argrity/widgets/kali_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:argrity/repositories/alumnos_repository.dart';
import 'package:argrity/repositories/turnos_repository.dart';
import 'package:argrity/repositories/pagos_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cubits/theme/theme_cubit.dart';

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

  // Cargamos .env en todas las plataformas (está en flutter assets, funciona en web también).
  // En producción web, --dart-define sobreescribe los valores del .env.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Silently ignore on production if .env is missing, we will rely on dart-defines
  }

  const buildUrl = String.fromEnvironment('SUPABASE_URL');
  const buildAnon = String.fromEnvironment('SUPABASE_ANON');

  final String url = buildUrl.isNotEmpty
      ? buildUrl
      : (dotenv.isInitialized ? (dotenv.env['URL'] ?? '') : '');
  final String anon = buildAnon.isNotEmpty
      ? buildAnon
      : (dotenv.isInitialized ? (dotenv.env['ANON'] ?? '') : '');

  if (url.isEmpty || anon.isEmpty) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error crítico: Faltan configurar las variables de entorno SUPABASE_URL y SUPABASE_ANON en el build.',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
    return;
  }

  await initializeDateFormatting('es_ES', null);
  await Supabase.initialize(
    url: url,
    publishableKey: anon,
  );
  SupaAuthClass.configure(url: url, anonKey: anon);

  final prefs = await SharedPreferences.getInstance();
  final initialThemeId = prefs.getString('selected_theme') ?? 'default';
  final initialIsDarkMode = prefs.getBool('is_dark_mode') ?? false;

  runApp(KaliApp(
      initialThemeId: initialThemeId, initialIsDarkMode: initialIsDarkMode));
}

// ─── KaliApp: crea y posee los BLoCs ─────────────────────────────────────────
//
// Es StatefulWidget para que el ciclo de vida de los BLoCs esté ligado
// al Estado del widget raíz, y no se recreen en cada hot reload / rebuild.
class KaliApp extends StatefulWidget {
  final String initialThemeId;
  final bool initialIsDarkMode;
  const KaliApp(
      {super.key,
      required this.initialThemeId,
      required this.initialIsDarkMode});

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
  late final ThemeCubit _themeCubit;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;

    final alumnosRepo = AlumnosRepository(client: supabaseClient);
    final turnosRepo = TurnosRepository(client: supabaseClient);
    final pagosRepo = PagosRepository(client: supabaseClient);

    _authBloc = AuthBloc();
    _navigationBloc = NavigationBloc();
    _activityBloc = ActivityBloc();
    _alumnosBloc = AlumnosBloc(
      activityBloc: _activityBloc,
      repository: alumnosRepo,
    );
    _turnosBloc = TurnosBloc(
      activityBloc: _activityBloc,
      repository: turnosRepo,
    );
    _pagosBloc = PagosBloc(repository: pagosRepo)..add(PagosLoadRequested());
    _dashboardBloc = DashboardBloc();
    _notificationsCubit = NotificationsCubit();
    _themeCubit = ThemeCubit(
        initialThemeId: widget.initialThemeId,
        initialIsDarkMode: widget.initialIsDarkMode);
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
    _themeCubit.close();
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
        BlocProvider.value(value: _themeCubit),
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
        // Limpiar acá cubre también los signOut() directos (InactiveScreen,
        // NewPasswordScreen, etc.) que no pasan por AuthBloc; si quedara el
        // caché del usuario anterior, AuthWrapper enrutaría con sus datos.
        ProfileCache.clear();
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
    // Splash con branding como estado inicial mientras se resuelve la sesión;
    // toda la navegación la maneja _navigatorKey dinámicamente.
    Widget home = const KaliSplash();

    return BlocBuilder<ThemeCubit, ThemeState>(builder: (context, themeState) {
      return MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Argity',
        theme: themeState.themeData,
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
    });
  }
}
