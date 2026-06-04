// Tests que cubren los casos límite en la generación de iniciales,
// incluyendo los bugs que existían con doble espacio y espacio inicial
// que causaban RangeError al hacer substring(0,1) sobre un string vacío.

import 'package:flutter_test/flutter_test.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/models/subscription.dart';

Student makeStudent(String name) => Student(
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

Subscription makeSub(String name) => Subscription(
      id: 'x',
      studentName: name,
      planName: 'Plan',
      price: 0,
      currency: 'ARS',
      startDate: DateTime(2024),
      endDate: DateTime(2024),
      status: 'active',
    );

void main() {
  group('Student.initials – casos normales', () {
    test('nombre de dos palabras devuelve primeras letras', () {
      expect(makeStudent('María Pérez').initials, 'MP');
    });

    test('nombre de una sola palabra devuelve primera letra', () {
      expect(makeStudent('Madonna').initials, 'M');
    });

    test('nombre vacío devuelve string vacío', () {
      expect(makeStudent('').initials, '');
    });

    test('nombre de tres palabras usa sólo las dos primeras', () {
      expect(makeStudent('Juan Carlos García').initials, 'JC');
    });
  });

  group('Student.initials – casos con espacios problemáticos (bug fix)', () {
    test('doble espacio entre palabras no lanza excepción', () {
      expect(() => makeStudent('Ana  Lopez').initials, returnsNormally);
    });

    test('doble espacio produce las iniciales correctas', () {
      expect(makeStudent('Ana  Lopez').initials, 'AL');
    });

    test('espacio inicial no lanza excepción', () {
      expect(() => makeStudent(' Ana Lopez').initials, returnsNormally);
    });

    test('espacio inicial produce las iniciales correctas', () {
      expect(makeStudent(' Ana Lopez').initials, 'AL');
    });

    test('sólo espacios devuelve string vacío', () {
      expect(makeStudent('   ').initials, '');
    });

    test('múltiples espacios entre palabras produce iniciales correctas', () {
      expect(makeStudent('Luis   Pérez').initials, 'LP');
    });
  });

  group('Subscription.studentInitials – casos normales', () {
    test('nombre de dos palabras devuelve iniciales', () {
      expect(makeSub('Ana López').studentInitials, 'AL');
    });

    test('nombre de una palabra devuelve primera letra', () {
      expect(makeSub('Roxanne').studentInitials, 'R');
    });

    test('nombre vacío devuelve string vacío', () {
      expect(makeSub('').studentInitials, '');
    });
  });

  group('Subscription.studentInitials – casos con espacios problemáticos (bug fix)', () {
    test('doble espacio no lanza excepción', () {
      expect(() => makeSub('Juan  García').studentInitials, returnsNormally);
    });

    test('doble espacio produce las iniciales correctas', () {
      expect(makeSub('Juan  García').studentInitials, 'JG');
    });

    test('espacio inicial no lanza excepción', () {
      expect(() => makeSub(' María García').studentInitials, returnsNormally);
    });

    test('espacio inicial produce las iniciales correctas', () {
      expect(makeSub(' María García').studentInitials, 'MG');
    });

    test('sólo espacios devuelve string vacío', () {
      expect(makeSub('   ').studentInitials, '');
    });
  });
}
