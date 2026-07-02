import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/models/turno.dart';

void main() {
  group('ClassSession.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'session-1',
          'group_id': null,
          'name': 'Reformer Pilates',
          'description': 'Clase de reformer',
          'date': '2024-03-04', // Monday
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 8,
          'status': 'scheduled',
          'cancellation_reason': null,
          'instructor_name': 'Ana García',
          'reservations': null,
        };

    test('parses basic fields correctly', () {
      final s = ClassSession.fromJson(base());
      expect(s.id, 'session-1');
      expect(s.name, 'Reformer Pilates');
      expect(s.date, DateTime(2024, 3, 4));
      expect(s.capacity, 8);
      expect(s.status, 'scheduled');
      expect(s.instructorName, 'Ana García');
      expect(s.groupId, isNull);
    });

    test('enrolled counts only non-cancelled reservations', () {
      final json = base()
        ..['reservations'] = [
          {
            'id': 'r1',
            'user_id': 'u1',
            'status': 'confirmed',
            'profiles': {'full_name': 'Pedro'}
          },
          {
            'id': 'r2',
            'user_id': 'u2',
            'status': 'cancelled',
            'profiles': {'full_name': 'María'}
          },
          {
            'id': 'r3',
            'user_id': 'u3',
            'status': 'attended',
            'profiles': {'full_name': 'Lucas'}
          },
        ];
      final s = ClassSession.fromJson(json);
      expect(s.enrolled, 2);
      expect(s.enrolledStudents.length, 2);
      expect(s.enrolledStudents.map((r) => r.studentName),
          containsAll(['Pedro', 'Lucas']));
    });

    test('enrolled is 0 when reservations is null', () {
      final s = ClassSession.fromJson(base());
      expect(s.enrolled, 0);
      expect(s.enrolledStudents, isEmpty);
    });

    test('null optional fields handled gracefully', () {
      final json = base()
        ..['instructor_name'] = null
        ..['description'] = null;
      final s = ClassSession.fromJson(json);
      expect(s.instructorName, isNull);
      expect(s.description, isNull);
    });
  });

  group('ClassSession time parsing', () {
    ClassSession make({required String start, required String end}) =>
        ClassSession.fromJson({
          'id': 'x',
          'name': 'Test',
          'date': '2024-03-04',
          'start_time': start,
          'end_time': end,
          'capacity': 5,
          'status': 'scheduled',
          'reservations': null,
        });

    test('parses HH:MM format', () {
      final s = make(start: '09:00', end: '10:30');
      expect(s.parsedStartTime, const TimeOfDay(hour: 9, minute: 0));
      expect(s.parsedEndTime, const TimeOfDay(hour: 10, minute: 30));
    });

    test('parses HH:MM:SS format (ignores seconds)', () {
      final s = make(start: '14:45:00', end: '15:30:00');
      expect(s.parsedStartTime, const TimeOfDay(hour: 14, minute: 45));
      expect(s.parsedEndTime, const TimeOfDay(hour: 15, minute: 30));
    });

    test('falls back to 0 for unparseable values', () {
      final s = make(start: 'bad', end: ':');
      expect(s.parsedStartTime, const TimeOfDay(hour: 0, minute: 0));
      expect(s.parsedEndTime, const TimeOfDay(hour: 0, minute: 0));
    });

    test('startTimeFormatted pads single-digit hour', () {
      final s = make(start: '9:05', end: '10:00');
      expect(s.startTimeFormatted, '09:05');
    });

    test('endTimeFormatted pads single-digit hour', () {
      final s = make(start: '10:00', end: '8:30');
      expect(s.endTimeFormatted, '08:30');
    });
  });

  group('ClassSession.dayIndex', () {
    ClassSession makeDate(String date) => ClassSession.fromJson({
          'id': 'x',
          'name': 'Test',
          'date': date,
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 5,
          'status': 'scheduled',
          'reservations': null,
        });

    test('Monday = 0', () => expect(makeDate('2024-03-04').dayIndex, 0));
    test('Tuesday = 1', () => expect(makeDate('2024-03-05').dayIndex, 1));
    test('Wednesday = 2', () => expect(makeDate('2024-03-06').dayIndex, 2));
    test('Saturday = 5', () => expect(makeDate('2024-03-09').dayIndex, 5));
    test('Sunday = 6', () => expect(makeDate('2024-03-10').dayIndex, 6));
  });

  group('ClassSession.uiTurnoType', () {
    ClassSession makeNamed(String name) => ClassSession.fromJson({
          'id': 'x',
          'name': name,
          'date': '2024-03-04',
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 5,
          'status': 'scheduled',
          'reservations': null,
        });

    test('name with "reformer" → reformerPilates', () {
      expect(
          makeNamed('Reformer Pilates').uiTurnoType, TurnoType.reformerPilates);
    });

    test('case-insensitive reformer match', () {
      expect(makeNamed('REFORMER AVANZADO').uiTurnoType,
          TurnoType.reformerPilates);
    });

    test('name with "mat" → matPilates', () {
      expect(makeNamed('Mat Pilates').uiTurnoType, TurnoType.matPilates);
    });

    test('name with "piso" → matPilates', () {
      expect(makeNamed('Pilates Piso').uiTurnoType, TurnoType.matPilates);
    });

    test('unrelated name → privateSpecial', () {
      expect(makeNamed('Yoga Flow').uiTurnoType, TurnoType.privateSpecial);
    });
  });

  group('ClassSession occupancy', () {
    test('occupancyText format', () {
      final s = ClassSession.fromJson({
        'id': 'x',
        'name': 'Test',
        'date': '2024-03-04',
        'start_time': '09:00',
        'end_time': '10:00',
        'capacity': 10,
        'status': 'scheduled',
        'reservations': [
          {
            'id': 'r1',
            'user_id': 'u1',
            'status': 'confirmed',
            'profiles': {'full_name': 'A'}
          },
          {
            'id': 'r2',
            'user_id': 'u2',
            'status': 'confirmed',
            'profiles': {'full_name': 'B'}
          },
        ],
      });
      expect(s.occupancyText, '2/10');
    });

    test('isFull when enrolled equals capacity', () {
      final s = ClassSession.fromJson({
        'id': 'x',
        'name': 'Test',
        'date': '2024-03-04',
        'start_time': '09:00',
        'end_time': '10:00',
        'capacity': 1,
        'status': 'scheduled',
        'reservations': [
          {
            'id': 'r1',
            'user_id': 'u1',
            'status': 'confirmed',
            'profiles': {'full_name': 'A'}
          },
        ],
      });
      expect(s.isFull, isTrue);
    });

    test('not full when enrolled is less than capacity', () {
      final s = ClassSession.fromJson({
        'id': 'x',
        'name': 'Test',
        'date': '2024-03-04',
        'start_time': '09:00',
        'end_time': '10:00',
        'capacity': 5,
        'status': 'scheduled',
        'reservations': null,
      });
      expect(s.isFull, isFalse);
    });
  });

  group('TurnoReservation.fromJson', () {
    test('extracts studentName from profiles', () {
      final r = TurnoReservation.fromJson({
        'id': 'rv1',
        'user_id': 'u1',
        'status': 'confirmed',
        'profiles': {'full_name': 'María López'},
      });
      expect(r.studentName, 'María López');
      expect(r.status, 'confirmed');
    });

    test('defaults studentName to "Sin nombre" when profiles is null', () {
      final r = TurnoReservation.fromJson({
        'id': 'rv1',
        'user_id': 'u1',
        'profiles': null,
      });
      expect(r.studentName, 'Sin nombre');
    });

    test('defaults status to "confirmed" when missing', () {
      final r = TurnoReservation.fromJson({
        'id': 'rv1',
        'user_id': 'u1',
        'profiles': null,
      });
      expect(r.status, 'confirmed');
    });
  });
}
