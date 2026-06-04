import 'package:flutter_test/flutter_test.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';
import 'package:argrity/models/student.dart';

Student makeStudent({
  required String id,
  String name = 'Test Student',
  String email = 'test@example.com',
  bool isActive = true,
  List<String> patologias = const [],
}) =>
    Student(
      id: id,
      name: name,
      email: email,
      plan: 'Plan',
      isActive: isActive,
      nextShift: '',
      shiftClass: '',
      createdAt: DateTime(2024),
      patologias: patologias,
    );

void main() {
  group('AlumnosLoaded.factory – filtrado', () {
    test('sin filtros devuelve todos los alumnos', () {
      final state = AlumnosLoaded(students: [
        makeStudent(id: '1'),
        makeStudent(id: '2'),
      ]);
      expect(state.filteredStudents.length, 2);
    });

    test('filtra por nombre (case-insensitive)', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', name: 'Ana García'),
          makeStudent(id: '2', name: 'Luis Pérez'),
        ],
        searchQuery: 'ana',
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '1');
    });

    test('filtra por email', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', email: 'ana@example.com'),
          makeStudent(id: '2', email: 'luis@other.com'),
        ],
        searchQuery: 'example',
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '1');
    });

    test('filtra por patología (case-insensitive)', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', patologias: ['Lumbalgia']),
          makeStudent(id: '2', patologias: ['escoliosis']),
          makeStudent(id: '3', patologias: []),
        ],
        patologiaFilter: 'lumbalgia',
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '1');
    });

    test('filtra por isActive = true', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', isActive: true),
          makeStudent(id: '2', isActive: false),
        ],
        isActiveFilter: true,
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '1');
    });

    test('filtra por isActive = false', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', isActive: true),
          makeStudent(id: '2', isActive: false),
        ],
        isActiveFilter: false,
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '2');
    });

    test('isActiveFilter = null devuelve todos', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', isActive: true),
          makeStudent(id: '2', isActive: false),
        ],
      );
      expect(state.filteredStudents.length, 2);
    });

    test('combina búsqueda + patología (AND)', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', name: 'Ana García', patologias: ['lumbalgia']),
          makeStudent(id: '2', name: 'Ana López', patologias: ['escoliosis']),
          makeStudent(id: '3', name: 'Luis García', patologias: ['lumbalgia']),
        ],
        searchQuery: 'ana',
        patologiaFilter: 'lumbalgia',
      );
      expect(state.filteredStudents.length, 1);
      expect(state.filteredStudents.first.id, '1');
    });

    test('devuelve lista vacía cuando ningún alumno coincide', () {
      final state = AlumnosLoaded(
        students: [makeStudent(id: '1', name: 'Luis')],
        searchQuery: 'XYZ_SIN_COINCIDENCIA',
      );
      expect(state.filteredStudents, isEmpty);
    });

    test('búsqueda en blanco equivale a sin filtro', () {
      final state = AlumnosLoaded(
        students: [makeStudent(id: '1'), makeStudent(id: '2')],
        searchQuery: '   ',
      );
      expect(state.filteredStudents.length, 2);
    });
  });

  group('AlumnosLoaded.availablePatologias', () {
    test('deduplica y ordena patologías de TODOS los alumnos', () {
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', patologias: ['lumbalgia', 'escoliosis']),
          makeStudent(id: '2', patologias: ['lumbalgia']),
          makeStudent(id: '3', patologias: ['artritis']),
        ],
      );
      expect(state.availablePatologias, ['artritis', 'escoliosis', 'lumbalgia']);
    });

    test('ignora strings vacíos en patologías', () {
      final state = AlumnosLoaded(
        students: [makeStudent(id: '1', patologias: ['', 'lumbalgia'])],
      );
      expect(state.availablePatologias, ['lumbalgia']);
    });

    test('es vacío cuando ningún alumno tiene patologías', () {
      final state = AlumnosLoaded(
        students: [makeStudent(id: '1', patologias: [])],
      );
      expect(state.availablePatologias, isEmpty);
    });

    test('incluye patologías de alumnos que NO pasan el filtro activo', () {
      // availablePatologias viene de TODOS los alumnos, no solo los filtrados
      final state = AlumnosLoaded(
        students: [
          makeStudent(id: '1', name: 'Ana', patologias: ['lumbalgia']),
          makeStudent(id: '2', name: 'Luis', patologias: ['artritis']),
        ],
        searchQuery: 'ana',
      );
      expect(state.availablePatologias, containsAll(['artritis', 'lumbalgia']));
    });
  });

  group('AlumnosLoaded – paginación', () {
    List<Student> makeStudents(int count) =>
        List.generate(count, (i) => makeStudent(id: '$i', name: 'Alumno $i'));

    test('4 alumnos = 1 página', () {
      expect(AlumnosLoaded(students: makeStudents(4)).totalPages, 1);
    });

    test('5 alumnos = 2 páginas', () {
      expect(AlumnosLoaded(students: makeStudents(5)).totalPages, 2);
    });

    test('8 alumnos = 2 páginas', () {
      expect(AlumnosLoaded(students: makeStudents(8)).totalPages, 2);
    });

    test('0 alumnos = mínimo 1 página', () {
      expect(AlumnosLoaded(students: []).totalPages, 1);
    });

    test('pageStudents devuelve los primeros 4 en página 1', () {
      final state = AlumnosLoaded(students: makeStudents(6));
      expect(state.pageStudents.length, 4);
      expect(state.pageStudents.first.id, '0');
    });

    test('pageStudents devuelve los sobrantes en la última página', () {
      final state = AlumnosLoaded(students: makeStudents(6), currentPage: 2);
      expect(state.pageStudents.length, 2);
    });

    test('pageStudents devuelve lista vacía cuando no hay resultados filtrados', () {
      final state = AlumnosLoaded(
        students: makeStudents(4),
        searchQuery: 'SIN_MATCH',
      );
      expect(state.pageStudents, isEmpty);
    });

    test('copyWithPage cambia sólo la página sin perder filtros', () {
      final state = AlumnosLoaded(
        students: makeStudents(8),
        searchQuery: 'Alumno',
      );
      final paged = state.copyWithPage(2);
      expect(paged.currentPage, 2);
      expect(paged.searchQuery, 'Alumno');
      expect(paged.filteredStudents.length, state.filteredStudents.length);
    });

    test('copyWithPage no recomputa filteredStudents', () {
      final state = AlumnosLoaded(students: makeStudents(4));
      final paged = state.copyWithPage(1);
      expect(identical(paged.filteredStudents, state.filteredStudents), isTrue);
    });
  });
}
