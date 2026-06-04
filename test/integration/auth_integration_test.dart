// Tests de integración contra Supabase real.
// Requieren .env con URL y ANON válidos.
// Crean un usuario real por cada corrida (email único con timestamp).
//
// Correr con:
//   flutter test test/integration/auth_integration_test.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/services/auth_service.dart';

// Storage en memoria para pkceAsyncStorage: evita que Supabase use
// SharedPreferencesGotrueAsyncStorage (que requiere platform channel).
class _InMemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _store = {};
  @override
  Future<String?> getItem({required String key}) async => _store[key];
  @override
  Future<void> removeItem({required String key}) async => _store.remove(key);
  @override
  Future<void> setItem({required String key, required String value}) async =>
      _store[key] = value;
}

void main() {
  late SupaAuthClass authService;

  // Email único por corrida para no colisionar con runs anteriores
  final ts = DateTime.now().millisecondsSinceEpoch;
  final testEmail = 'integration_test_$ts@testargity.com';
  const testPassword = 'TestPassword123!';
  const testName = 'Integration Test User';

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['URL'] ?? '';
    final anon = dotenv.env['ANON'] ?? '';

    try {
      // EmptyLocalStorage evita depender del plugin shared_preferences
      // (que no está disponible en el runner de tests sin dispositivo).
      await Supabase.initialize(
        url: url,
        anonKey: anon,
        authOptions: FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: _InMemoryAsyncStorage(),
        ),
      );
    } catch (_) {
      // Ya inicializado por otra suite de tests
    }
    SupaAuthClass.configure(url: url, anonKey: anon);
    authService = SupaAuthClass();
  });

  tearDownAll(() async {
    // Mejor esfuerzo: cerrar sesión si quedó abierta
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  });

  // ─────────────────────────────────────────────────────────────────────────
  // REGISTRO
  // ─────────────────────────────────────────────────────────────────────────
  group('Registro — crear cuenta nueva', () {
    test('registrarUsuario devuelve Pending', () async {
      final result =
          await authService.registrarUsuario(testEmail, testPassword, testName);

      expect(
        result,
        equals('Pending'),
        reason:
            'El registro debe completarse sin errores y devolver "Pending". '
            'Resultado recibido: "$result"',
      );
    });

    test('El perfil se crea en la tabla profiles con datos correctos', () async {
      // Iniciamos sesión directamente (sin pasar por logInUsuario) para
      // inspeccionar el estado crudo de la DB sin que el control de roles interfiera.
      final client = Supabase.instance.client;
      late AuthResponse signInResp;

      try {
        signInResp = await client.auth.signInWithPassword(
          email: testEmail,
          password: testPassword,
        );
      } catch (e) {
        fail(
          'No se pudo iniciar sesión con el usuario recién creado: $e\n'
          'Si la confirmación de email está habilitada en Supabase, '
          'desactivala para tests de desarrollo.',
        );
      }

      expect(
        signInResp.user,
        isNotNull,
        reason: 'El usuario debe existir en auth.users después del registro',
      );

      final profile = await client
          .from('profiles')
          .select('id, email, full_name, role, is_active')
          .eq('id', signInResp.user!.id)
          .maybeSingle();

      await client.auth.signOut();

      expect(
        profile,
        isNotNull,
        reason:
            'Debe existir una fila en profiles para el usuario recién registrado',
      );
      expect(
        profile!['email'],
        equals(testEmail),
        reason: 'El email del perfil debe coincidir',
      );
      expect(
        profile['full_name'],
        equals(testName),
        reason: 'El nombre completo del perfil debe coincidir',
      );
      expect(
        profile['role'],
        equals('sudo'),
        reason: 'El rol debe ser sudo para el dueño de una institución',
      );
      expect(
        profile['is_active'],
        isFalse,
        reason:
            'El usuario nuevo debe quedar inactivo hasta ser activado por un admin',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────────────────
  group('Inicio de sesión', () {
    test('logInUsuario autentifica usuario sudo y devuelve Ok', () async {
      final result = await authService.logInUsuario(testEmail, testPassword);

      expect(
        result,
        equals('Ok'),
        reason:
            'El login de un usuario sudo debe ser exitoso. '
            'Resultado recibido: "$result"',
      );

      final user = Supabase.instance.client.auth.currentUser;
      expect(
        user,
        isNotNull,
        reason: 'Debe haber sesión activa después de logInUsuario exitoso',
      );
      expect(user!.email, equals(testEmail));

      await Supabase.instance.client.auth.signOut();
    });

    test('logInUsuario rechaza contraseña incorrecta', () async {
      final result =
          await authService.logInUsuario(testEmail, 'contraseña_incorrecta!');

      expect(
        result,
        isNot(equals('Ok')),
        reason: 'Login con contraseña incorrecta debe fallar',
      );
      expect(
        Supabase.instance.client.auth.currentUser,
        isNull,
        reason: 'No debe haber sesión activa tras login fallido',
      );
    });

    test('logInUsuario rechaza email inexistente', () async {
      final result = await authService.logInUsuario(
          'noexiste_$ts@testargity.com', testPassword);

      expect(
        result,
        isNot(equals('Ok')),
        reason: 'Login de usuario inexistente debe fallar',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // INSTITUCIÓN
  // ─────────────────────────────────────────────────────────────────────────
  group('Institución — crear y vincular al perfil', () {
    // Nombre único para no colisionar entre corridas
    final instName = 'Test Studio $ts';
    final instSlug = 'test-studio-$ts';

    test('RPC create_institution crea la fila en la tabla institutions',
        () async {
      final client = Supabase.instance.client;

      // Iniciar sesión como el usuario de test
      await client.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );
      expect(client.auth.currentUser, isNotNull,
          reason: 'Necesitamos sesión activa para crear la institución');

      // Llamar al mismo RPC que usa InstitutionSelectionScreen
      try {
        await client.rpc('create_institution', params: {
          'inst_name': instName,
          'inst_slug': instSlug,
        });
      } catch (e) {
        fail(
          'La función RPC create_institution falló: $e\n'
          'Verificá que existe en Supabase con:\n'
          '  CREATE OR REPLACE FUNCTION create_institution(...) ...',
        );
      }

      // Verificar que la institución existe en la tabla
      final inst = await client
          .from('institutions')
          .select('id, name, slug')
          .eq('slug', instSlug)
          .maybeSingle();

      expect(
        inst,
        isNotNull,
        reason: 'La institución debe existir en la tabla institutions',
      );
      expect(inst!['name'], equals(instName));
      expect(inst['slug'], equals(instSlug));

      // Guardar el ID para el siguiente test (via shared state a través del slug)
      await client.auth.signOut();
    });

    test('El perfil queda vinculado a la institución', () async {
      final client = Supabase.instance.client;

      await client.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );

      // Obtener ID de la institución recién creada
      final inst = await client
          .from('institutions')
          .select('id')
          .eq('slug', instSlug)
          .single();
      final instId = inst['id'] as String;

      // Vincular (misma lógica que InstitutionSelectionScreen)
      final userId = client.auth.currentUser!.id;
      await client.from('profiles').update({
        'institution_id': instId,
        'role': 'sudo',
      }).eq('id', userId);

      // Verificar que el perfil ahora tiene institution_id
      final profile = await client
          .from('profiles')
          .select('institution_id, role')
          .eq('id', userId)
          .single();

      await client.auth.signOut();

      expect(
        profile['institution_id'],
        equals(instId),
        reason: 'El perfil debe tener el institution_id asignado',
      );
      expect(
        profile['role'],
        equals('sudo'),
        reason: 'El rol debe ser sudo',
      );
    });
  });
}
