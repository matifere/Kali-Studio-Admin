import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/models/schedule_template.dart';

void main() {
  group('ScheduleTemplate.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'tmpl-1',
          'name': 'Reformer Avanzado',
          'description': 'Clase intensa',
          'day_of_week': 'monday',
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 8,
          'instructor_name': 'Ana García',
          'is_active': true,
        };

    test('parses all fields', () {
      final t = ScheduleTemplate.fromJson(base());
      expect(t.id, 'tmpl-1');
      expect(t.name, 'Reformer Avanzado');
      expect(t.description, 'Clase intensa');
      expect(t.dayOfWeek, 'monday');
      expect(t.startTime, '09:00');
      expect(t.endTime, '10:00');
      expect(t.capacity, 8);
      expect(t.instructorName, 'Ana García');
      expect(t.isActive, isTrue);
    });

    test('is_active defaults to true when null', () {
      final json = base()..['is_active'] = null;
      final t = ScheduleTemplate.fromJson(json);
      expect(t.isActive, isTrue);
    });

    test('description and instructor can be null', () {
      final json = base()
        ..['description'] = null
        ..['instructor_name'] = null;
      final t = ScheduleTemplate.fromJson(json);
      expect(t.description, isNull);
      expect(t.instructorName, isNull);
    });
  });

  group('ScheduleTemplate.dayIndex', () {
    ScheduleTemplate make(String day) => ScheduleTemplate.fromJson({
          'id': 'x',
          'name': 'Test',
          'day_of_week': day,
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 5,
          'is_active': true,
        });

    test('monday → 0', () => expect(make('monday').dayIndex, 0));
    test('tuesday → 1', () => expect(make('tuesday').dayIndex, 1));
    test('wednesday → 2', () => expect(make('wednesday').dayIndex, 2));
    test('thursday → 3', () => expect(make('thursday').dayIndex, 3));
    test('friday → 4', () => expect(make('friday').dayIndex, 4));
    test('saturday → 5', () => expect(make('saturday').dayIndex, 5));
    test('sunday → 6', () => expect(make('sunday').dayIndex, 6));
    test('unknown falls back to 0', () => expect(make('invalid').dayIndex, 0));

    test('case-insensitive matching', () {
      expect(make('Monday').dayIndex, 0);
      expect(make('WEDNESDAY').dayIndex, 2);
    });
  });

  group('ScheduleTemplate.dayNameSpanish', () {
    ScheduleTemplate make(String day) => ScheduleTemplate.fromJson({
          'id': 'x',
          'name': 'Test',
          'day_of_week': day,
          'start_time': '09:00',
          'end_time': '10:00',
          'capacity': 5,
          'is_active': true,
        });

    test('monday → Lunes', () => expect(make('monday').dayNameSpanish, 'Lunes'));
    test('tuesday → Martes', () => expect(make('tuesday').dayNameSpanish, 'Martes'));
    test('wednesday → Miércoles', () => expect(make('wednesday').dayNameSpanish, 'Miércoles'));
    test('thursday → Jueves', () => expect(make('thursday').dayNameSpanish, 'Jueves'));
    test('friday → Viernes', () => expect(make('friday').dayNameSpanish, 'Viernes'));
    test('saturday → Sábado', () => expect(make('saturday').dayNameSpanish, 'Sábado'));
    test('sunday → Domingo', () => expect(make('sunday').dayNameSpanish, 'Domingo'));
  });
}
