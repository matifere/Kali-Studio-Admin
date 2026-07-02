import 'package:flutter_test/flutter_test.dart';
import 'package:argrity/models/student.dart';

void main() {
  group('Student.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'student-1',
          'avatar_url': null,
          'full_name': 'María Pérez',
          'email': 'maria@example.com',
          'is_active': true,
          'created_at': '2023-01-15T00:00:00',
          'patologias': ['lumbalgia'],
          'subscriptions': null,
          'reservations': null,
        };

    test('parses basic fields', () {
      final s = Student.fromJson(base());
      expect(s.id, 'student-1');
      expect(s.name, 'María Pérez');
      expect(s.email, 'maria@example.com');
      expect(s.isActive, isTrue);
      expect(s.patologias, ['lumbalgia']);
    });

    test('falls back to defaults when fields are null', () {
      final s = Student.fromJson({
        'subscriptions': null,
        'reservations': null,
      });
      expect(s.id, '');
      expect(s.name, 'Sin nombre');
      expect(s.email, 'correo@pendiente.com');
      expect(s.plan, 'Sin plan');
      expect(s.nextShift, 'Sin turno asignado');
      expect(s.shiftClass, 'Sin clase');
      expect(s.isActive, isFalse);
      expect(s.patologias, isEmpty);
    });

    test('picks active subscription over non-active', () {
      final s = Student.fromJson({
        ...base(),
        'subscriptions': <dynamic>[
          <String, dynamic>{
            'status': 'expired',
            'plans': <String, dynamic>{'name': 'Plan Vencido'},
            'end_date': '2023-06-01',
          },
          <String, dynamic>{
            'status': 'active',
            'plans': <String, dynamic>{'name': 'Plan Premium'},
            'end_date': '2024-06-01',
          },
        ],
      });
      expect(s.plan, 'Plan Premium');
    });

    test('falls back to first subscription when none is active', () {
      final s = Student.fromJson({
        ...base(),
        'subscriptions': <dynamic>[
          <String, dynamic>{
            'status': 'expired',
            'plans': <String, dynamic>{'name': 'Plan A'},
            'end_date': '2023-01-01',
          },
          <String, dynamic>{
            'status': 'cancelled',
            'plans': <String, dynamic>{'name': 'Plan B'},
            'end_date': '2023-06-01',
          },
        ],
      });
      expect(s.plan, 'Plan A');
    });

    test('plan is "Sin plan" when subscriptions list is empty', () {
      final s = Student.fromJson({...base(), 'subscriptions': []});
      expect(s.plan, 'Sin plan');
    });

    test('parses planEndDate from subscription end_date', () {
      final s = Student.fromJson({
        ...base(),
        'subscriptions': <dynamic>[
          <String, dynamic>{
            'status': 'active',
            'plans': <String, dynamic>{'name': 'Plan X'},
            'end_date': '2024-12-31',
          },
        ],
      });
      expect(s.planEndDate, DateTime(2024, 12, 31));
    });

    test('nextShift es la reserva futura más próxima (no la primera de la lista)', () {
      final now = DateTime.now();
      String inDays(int d) {
        final dt = now.add(Duration(days: d));
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }

      final s = Student.fromJson({
        ...base(),
        'reservations': [
          // Más lejana primero: el orden de la query no garantiza nada.
          {
            'status': 'confirmed',
            'class_sessions': {
              'name': 'Mat Pilates',
              'date': inDays(10),
              'start_time': '10:00',
            },
          },
          {
            'status': 'confirmed',
            'class_sessions': {
              'name': 'Reformer Pilates',
              'date': inDays(3),
              'start_time': '10:00',
            },
          },
          // Cancelada aún más cercana: debe ignorarse.
          {
            'status': 'cancelled',
            'class_sessions': {
              'name': 'Cancelada',
              'date': inDays(1),
              'start_time': '10:00',
            },
          },
        ],
      });
      expect(s.shiftClass, 'Reformer Pilates');
      expect(s.nextShift, isNot('Sin turno asignado'));
    });

    test('las reservas pasadas no cuentan como próximo turno', () {
      final s = Student.fromJson({
        ...base(),
        'reservations': [
          {
            'status': 'attended',
            'class_sessions': {
              'name': 'Reformer Pilates',
              'date': '2024-03-15',
              'start_time': '10:00',
            },
          },
        ],
      });
      expect(s.nextShift, 'Sin turno asignado');
      expect(s.shiftClass, 'Sin clase');
    });

    test('attendedThisMonth counts only current-month attended reservations', () {
      final now = DateTime.now();
      final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}-10';
      final lastMonth = now.month == 1
          ? '${now.year - 1}-12-10'
          : '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-10';

      final s = Student.fromJson({
        ...base(),
        'reservations': [
          {
            'status': 'attended',
            'class_sessions': {'date': thisMonth},
          },
          {
            'status': 'attended',
            'class_sessions': {'date': thisMonth},
          },
          {
            'status': 'attended',
            'class_sessions': {'date': lastMonth},
          },
          {
            'status': 'confirmed',
            'class_sessions': {'date': thisMonth},
          },
        ],
      });
      expect(s.attendedThisMonth, 2);
    });

    test('patologias is empty list when null in json', () {
      final s = Student.fromJson({...base(), 'patologias': null});
      expect(s.patologias, isEmpty);
    });
  });

  group('Student.initials', () {
    Student make(String name) => Student(
          id: 'x',
          name: name,
          email: 'a@b.com',
          plan: 'Plan',
          isActive: true,
          nextShift: '',
          shiftClass: '',
          createdAt: DateTime(2024),
          patologias: [],
        );

    test('two-word name → first letters of each word', () {
      expect(make('María Pérez').initials, 'MP');
    });

    test('single-word name → first letter only', () {
      expect(make('Madonna').initials, 'M');
    });

    test('empty name → empty string', () {
      expect(make('').initials, '');
    });

    test('three-word name → first two words', () {
      // Only uses first two words per the model logic
      expect(make('Juan Carlos García').initials, 'JC');
    });
  });


}
