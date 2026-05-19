import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/services/profile_cache.dart';

void main() {
  setUp(() => ProfileCache.clear());
  tearDown(() => ProfileCache.clear());

  group('ProfileCache initial state', () {
    test('role defaults to "sudo"', () {
      expect(ProfileCache.role, 'sudo');
    });

    test('institutionId defaults to null', () {
      expect(ProfileCache.institutionId, isNull);
    });

    test('isSudo is true initially', () {
      expect(ProfileCache.isSudo, isTrue);
    });

    test('isAdmin is false initially', () {
      expect(ProfileCache.isAdmin, isFalse);
    });
  });

  group('ProfileCache.set', () {
    test('updates role', () {
      ProfileCache.set(role: 'admin');
      expect(ProfileCache.role, 'admin');
    });

    test('updates institutionId', () {
      ProfileCache.set(role: 'admin', institutionId: 'inst-42');
      expect(ProfileCache.institutionId, 'inst-42');
    });

    test('isAdmin true after setting role to admin', () {
      ProfileCache.set(role: 'admin');
      expect(ProfileCache.isAdmin, isTrue);
      expect(ProfileCache.isSudo, isFalse);
    });

    test('isSudo true after setting role to sudo', () {
      ProfileCache.set(role: 'admin'); // change away first
      ProfileCache.set(role: 'sudo');
      expect(ProfileCache.isSudo, isTrue);
      expect(ProfileCache.isAdmin, isFalse);
    });

    test('client role is neither isAdmin nor isSudo', () {
      ProfileCache.set(role: 'client');
      expect(ProfileCache.isAdmin, isFalse);
      expect(ProfileCache.isSudo, isFalse);
      expect(ProfileCache.role, 'client');
    });

    test('institutionId can be set to null explicitly', () {
      ProfileCache.set(role: 'admin', institutionId: 'inst-1');
      ProfileCache.set(role: 'admin', institutionId: null);
      expect(ProfileCache.institutionId, isNull);
    });
  });

  group('ProfileCache.clear', () {
    test('resets role to sudo', () {
      ProfileCache.set(role: 'admin');
      ProfileCache.clear();
      expect(ProfileCache.role, 'sudo');
    });

    test('resets institutionId to null', () {
      ProfileCache.set(role: 'admin', institutionId: 'inst-99');
      ProfileCache.clear();
      expect(ProfileCache.institutionId, isNull);
    });

    test('isSudo is true after clear', () {
      ProfileCache.set(role: 'client');
      ProfileCache.clear();
      expect(ProfileCache.isSudo, isTrue);
    });

    test('isAdmin is false after clear', () {
      ProfileCache.set(role: 'admin');
      ProfileCache.clear();
      expect(ProfileCache.isAdmin, isFalse);
    });
  });

  group('ProfileCache isolation between tests', () {
    test('first test sets admin', () {
      ProfileCache.set(role: 'admin', institutionId: 'inst-a');
      expect(ProfileCache.isAdmin, isTrue);
    });

    test('setUp clears state so second test starts fresh', () {
      // setUp runs before each test — role should be back to sudo here
      expect(ProfileCache.role, 'sudo');
      expect(ProfileCache.institutionId, isNull);
    });
  });
}
