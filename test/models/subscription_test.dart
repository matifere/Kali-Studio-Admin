import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/models/subscription.dart';

void main() {
  group('Subscription.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'sub-1',
          'profiles': {'full_name': 'Juan García', 'avatar_url': null},
          'plans': {'name': 'Plan Mensual', 'price': 15000.0, 'currency': 'ARS'},
          'start_date': '2024-01-01',
          'end_date': '2024-01-31',
          'status': 'active',
        };

    test('parses all fields correctly', () {
      final s = Subscription.fromJson(base());
      expect(s.id, 'sub-1');
      expect(s.studentName, 'Juan García');
      expect(s.planName, 'Plan Mensual');
      expect(s.price, 15000.0);
      expect(s.currency, 'ARS');
      expect(s.startDate, DateTime(2024, 1, 1));
      expect(s.endDate, DateTime(2024, 1, 31));
      expect(s.status, 'active');
    });

    test('accepts profiles as a List (Supabase join format)', () {
      final json = base()
        ..['profiles'] = [
          {'full_name': 'Lucía Díaz', 'avatar_url': null}
        ];
      final s = Subscription.fromJson(json);
      expect(s.studentName, 'Lucía Díaz');
    });

    test('accepts plans as a List (Supabase join format)', () {
      final json = base()
        ..['plans'] = [
          {'name': 'Plan Trimestral', 'price': 40000.0, 'currency': 'ARS'}
        ];
      final s = Subscription.fromJson(json);
      expect(s.planName, 'Plan Trimestral');
      expect(s.price, 40000.0);
    });

    test('falls back when profiles is null', () {
      final json = base()..['profiles'] = null;
      final s = Subscription.fromJson(json);
      expect(s.studentName, 'Desconocido');
      expect(s.avatarUrl, isNull);
    });

    test('falls back when plans is null', () {
      final json = base()..['plans'] = null;
      final s = Subscription.fromJson(json);
      expect(s.planName, 'Sin plan');
      expect(s.price, 0.0);
      expect(s.currency, 'ARS');
    });

    test('defaults status to "pending" when null', () {
      final json = base()..['status'] = null;
      final s = Subscription.fromJson(json);
      expect(s.status, 'pending');
    });

    test('handles null dates gracefully', () {
      final json = base()
        ..['start_date'] = null
        ..['end_date'] = null;
      final s = Subscription.fromJson(json);
      expect(s.startDate, isA<DateTime>());
      expect(s.endDate, isA<DateTime>());
    });
  });

  group('Subscription.statusLabel', () {
    Subscription make(String status) => Subscription.fromJson({
          'id': 'x',
          'status': status,
          'profiles': {'full_name': 'Test'},
          'plans': {'name': 'Plan', 'price': 0, 'currency': 'ARS'},
          'start_date': '2024-01-01',
          'end_date': '2024-01-31',
        });

    test('active → ACTIVO', () => expect(make('active').statusLabel, 'ACTIVO'));
    test('pending → PENDIENTE', () => expect(make('pending').statusLabel, 'PENDIENTE'));
    test('expired → VENCIDO', () => expect(make('expired').statusLabel, 'VENCIDO'));
    test('cancelled → CANCELADO', () => expect(make('cancelled').statusLabel, 'CANCELADO'));
    test('unknown → uppercased value', () => expect(make('custom').statusLabel, 'CUSTOM'));
  });

  group('Subscription.statusColor', () {
    Subscription make(String status) => Subscription.fromJson({
          'id': 'x',
          'status': status,
          'profiles': {'full_name': 'Test'},
          'plans': {'name': 'Plan', 'price': 0, 'currency': 'ARS'},
          'start_date': '2024-01-01',
          'end_date': '2024-01-31',
        });

    test('active is green', () => expect(make('active').statusColor, const Color(0xFF5C9E6C)));
    test('pending is yellow', () => expect(make('pending').statusColor, const Color(0xFFD4A836)));
    test('expired is red', () => expect(make('expired').statusColor, const Color(0xFFD4685C)));
    test('cancelled is red', () => expect(make('cancelled').statusColor, const Color(0xFFD4685C)));
    test('unknown is grey', () => expect(make('unknown').statusColor, Colors.grey));
  });

  group('Subscription.studentInitials', () {
    Subscription make(String name) => Subscription(
          id: 'x',
          studentName: name,
          planName: 'Plan',
          price: 0,
          currency: 'ARS',
          startDate: DateTime(2024),
          endDate: DateTime(2024),
          status: 'active',
        );

    test('two-word name → initials', () => expect(make('Ana López').studentInitials, 'AL'));
    test('single word → first letter', () => expect(make('Roxanne').studentInitials, 'R'));
    test('empty string → empty', () => expect(make('').studentInitials, ''));
  });

  group('Subscription date formatting', () {
    test('startDateFormatted and endDateFormatted', () {
      final s = Subscription.fromJson({
        'id': 'x',
        'profiles': {'full_name': 'Test'},
        'plans': {'name': 'Plan', 'price': 0, 'currency': 'ARS'},
        'start_date': '2024-03-01',
        'end_date': '2024-03-31',
        'status': 'active',
      });
      expect(s.startDateFormatted, '01 Mar 2024');
      expect(s.endDateFormatted, '31 Mar 2024');
    });

    test('month abbreviations for all months', () {
      final months = {
        '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr',
        '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Ago',
        '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic',
      };
      for (final entry in months.entries) {
        final s = Subscription.fromJson({
          'id': 'x',
          'profiles': {'full_name': 'Test'},
          'plans': {'name': 'Plan', 'price': 0, 'currency': 'ARS'},
          'start_date': '2024-${entry.key}-15',
          'end_date': '2024-${entry.key}-15',
          'status': 'active',
        });
        expect(s.startDateFormatted, contains(entry.value),
            reason: 'Month ${entry.key} should abbreviate to ${entry.value}');
      }
    });
  });

  group('Subscription.amountFormatted', () {
    test('formats price with 2 decimals and currency', () {
      final s = Subscription(
        id: 'x',
        studentName: 'A',
        planName: 'Plan',
        price: 15000.5,
        currency: 'ARS',
        startDate: DateTime(2024),
        endDate: DateTime(2024),
        status: 'active',
      );
      expect(s.amountFormatted, r'$15000.50 ARS');
    });
  });

  group('Subscription.copyWith', () {
    test('updates only specified fields', () {
      final original = Subscription.fromJson({
        'id': 'sub-1',
        'profiles': {'full_name': 'Juan'},
        'plans': {'name': 'Plan', 'price': 1000, 'currency': 'ARS'},
        'start_date': '2024-01-01',
        'end_date': '2024-01-31',
        'status': 'active',
      });
      final updated = original.copyWith(status: 'expired');
      expect(updated.status, 'expired');
      expect(updated.id, 'sub-1');
      expect(updated.studentName, 'Juan');
    });
  });
}
