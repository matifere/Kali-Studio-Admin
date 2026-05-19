import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/models/class_session.dart';

// Helper to build a minimal ClassSession for state tests.
ClassSession makeSession({
  required String id,
  String name = 'Reformer Pilates',
  String? instructor,
  String startTime = '09:00',
  String endTime = '10:00',
  int dayOffset = 0,
}) {
  final date = DateTime(2024, 3, 4).add(Duration(days: dayOffset));
  return ClassSession.fromJson({
    'id': id,
    'name': name,
    'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'start_time': startTime,
    'end_time': endTime,
    'capacity': 8,
    'status': 'scheduled',
    'instructor_name': instructor,
    'reservations': null,
  });
}

final kWeekStart = DateTime(2024, 3, 4);

void main() {
  group('TurnosState.availableInstructors', () {
    test('empty when no sessions', () {
      final state = TurnosState(currentWeekStart: kWeekStart, sessions: []);
      expect(state.availableInstructors, isEmpty);
    });

    test('deduplicates instructors', () {
      final state = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: [
          makeSession(id: '1', instructor: 'Ana'),
          makeSession(id: '2', instructor: 'Ana'),
          makeSession(id: '3', instructor: 'Luis'),
        ],
      );
      expect(state.availableInstructors, ['Ana', 'Luis']);
    });

    test('excludes sessions with null or empty instructor', () {
      final state = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: [
          makeSession(id: '1', instructor: null),
          makeSession(id: '2', instructor: ''),
          makeSession(id: '3', instructor: 'Marta'),
        ],
      );
      expect(state.availableInstructors, ['Marta']);
    });

    test('returns sorted list', () {
      final state = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: [
          makeSession(id: '1', instructor: 'Zoé'),
          makeSession(id: '2', instructor: 'Ana'),
          makeSession(id: '3', instructor: 'Luis'),
        ],
      );
      expect(state.availableInstructors, ['Ana', 'Luis', 'Zoé']);
    });
  });

  group('TurnosState.availableRooms', () {
    test('empty when no sessions', () {
      final state = TurnosState(currentWeekStart: kWeekStart, sessions: []);
      expect(state.availableRooms, isEmpty);
    });

    test('deduplicates session names used as room identifiers', () {
      final state = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: [
          makeSession(id: '1', name: 'Reformer Pilates'),
          makeSession(id: '2', name: 'Reformer Pilates'),
          makeSession(id: '3', name: 'Mat Pilates'),
        ],
      );
      expect(state.availableRooms, ['Mat Pilates', 'Reformer Pilates']);
    });
  });

  group('TurnosState.filteredSessions', () {
    late TurnosState state;

    setUp(() {
      state = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: [
          makeSession(id: '1', name: 'Reformer Pilates', instructor: 'Ana'),
          makeSession(id: '2', name: 'Mat Pilates', instructor: 'Luis'),
          makeSession(id: '3', name: 'Reformer Pilates', instructor: 'Luis'),
        ],
      );
    });

    test('returns all sessions when no filters applied', () {
      expect(state.filteredSessions.length, 3);
      expect(identical(state.filteredSessions, state.sessions), isTrue,
          reason: 'should return same list reference to avoid a copy');
    });

    test('filters by instructor', () {
      final filtered = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: state.sessions,
        selectedInstructor: 'Ana',
      ).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filters by room (session name)', () {
      final filtered = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: state.sessions,
        selectedRoom: 'Mat Pilates',
      ).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('filters by both instructor and room', () {
      final filtered = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: state.sessions,
        selectedInstructor: 'Luis',
        selectedRoom: 'Reformer Pilates',
      ).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.id, '3');
    });

    test('returns empty list when no sessions match filters', () {
      final filtered = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: state.sessions,
        selectedInstructor: 'Desconocido',
      ).filteredSessions;
      expect(filtered, isEmpty);
    });

    test('empty string instructor treated as no filter', () {
      final filtered = TurnosState(
        currentWeekStart: kWeekStart,
        sessions: state.sessions,
        selectedInstructor: '',
      ).filteredSessions;
      expect(filtered.length, 3);
    });
  });

  group('TurnosState.hasSelection', () {
    test('false when selectedTurno is null', () {
      final state = TurnosState(currentWeekStart: kWeekStart);
      expect(state.hasSelection, isFalse);
    });

    test('true when selectedTurno is set', () {
      final state = TurnosState(
        currentWeekStart: kWeekStart,
        selectedTurno: makeSession(id: '1'),
      );
      expect(state.hasSelection, isTrue);
    });
  });

  group('TurnosState.copyWith', () {
    late TurnosState base;

    setUp(() {
      base = TurnosState(
        currentWeekStart: kWeekStart,
        isLoading: false,
        error: 'prev error',
        selectedTurno: makeSession(id: 'sel'),
        sessions: [makeSession(id: 'A')],
      );
    });

    test('updates sessions', () {
      final updated = base.copyWith(sessions: []);
      expect(updated.sessions, isEmpty);
      expect(updated.error, 'prev error'); // unchanged
    });

    test('clearError removes existing error', () {
      final updated = base.copyWith(clearError: true);
      expect(updated.error, isNull);
    });

    test('setting error without clearError preserves new error', () {
      final updated = base.copyWith(error: 'new error');
      expect(updated.error, 'new error');
    });

    test('clearSelection removes selectedTurno', () {
      final updated = base.copyWith(clearSelection: true);
      expect(updated.selectedTurno, isNull);
      expect(updated.hasSelection, isFalse);
    });

    test('new selectedTurno replaces existing without clearSelection', () {
      final newTurno = makeSession(id: 'new-sel');
      final updated = base.copyWith(selectedTurno: newTurno);
      expect(updated.selectedTurno!.id, 'new-sel');
    });

    test('clearSelection takes priority over new selectedTurno', () {
      final newTurno = makeSession(id: 'new');
      final updated = base.copyWith(
        clearSelection: true,
        selectedTurno: newTurno,
      );
      expect(updated.selectedTurno, isNull);
    });

    test('updates isLoading', () {
      final updated = base.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('updates currentWeekStart', () {
      final newWeek = DateTime(2024, 3, 11);
      final updated = base.copyWith(currentWeekStart: newWeek);
      expect(updated.currentWeekStart, newWeek);
    });

    test('selectedInstructor setter via function', () {
      final updated = base.copyWith(selectedInstructor: () => 'Ana');
      expect(updated.selectedInstructor, 'Ana');
    });

    test('selectedInstructor cleared by passing () => null', () {
      final withInstructor = base.copyWith(selectedInstructor: () => 'Ana');
      final cleared = withInstructor.copyWith(selectedInstructor: () => null);
      expect(cleared.selectedInstructor, isNull);
    });

    test('null selectedInstructor function preserves original', () {
      final withInstructor = base.copyWith(selectedInstructor: () => 'Ana');
      final preserved = withInstructor.copyWith();
      expect(preserved.selectedInstructor, 'Ana');
    });

    test('copyWith does not mutate original state', () {
      base.copyWith(isLoading: true, clearError: true);
      expect(base.isLoading, isFalse);
      expect(base.error, 'prev error');
    });
  });
}
