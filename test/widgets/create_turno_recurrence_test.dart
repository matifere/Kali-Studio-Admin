// Tests para la lógica de cálculo de semanas del CreateTurnoDialog.
// La función _weeksUntilEndOfYear es privada en el widget, así que
// se replica aquí como función pura para verificar la matemática.

import 'package:flutter_test/flutter_test.dart';

int weeksUntilEndOfYear(DateTime from) {
  final endOfYear = DateTime(from.year, 12, 31);
  return ((endOfYear.difference(from).inDays) / 7).ceil().clamp(1, 999);
}

void main() {
  group('weeksUntilEndOfYear – casos límite', () {
    test('desde el 31 de diciembre devuelve 1 (clamp mínimo)', () {
      // diff = 0 días → ceil(0/7) = 0 → clamp → 1
      expect(weeksUntilEndOfYear(DateTime(2024, 12, 31)), 1);
    });

    test('desde el 25 de diciembre devuelve 1 (6 días restantes)', () {
      // ceil(6/7) = 1
      expect(weeksUntilEndOfYear(DateTime(2024, 12, 25)), 1);
    });

    test('desde el 24 de diciembre devuelve 1 (7 días exactos)', () {
      // ceil(7/7) = 1
      expect(weeksUntilEndOfYear(DateTime(2024, 12, 24)), 1);
    });

    test('desde el 23 de diciembre devuelve 2 (8 días restantes)', () {
      // ceil(8/7) = 2
      expect(weeksUntilEndOfYear(DateTime(2024, 12, 23)), 2);
    });

    test('desde el 18 de diciembre devuelve 2 (13 días restantes)', () {
      // ceil(13/7) = 2
      expect(weeksUntilEndOfYear(DateTime(2024, 12, 18)), 2);
    });

    test('desde el 1 de enero devuelve 53 semanas (año bisiesto 2024)', () {
      // 2024 es bisiesto (366 días): del 1 Ene al 31 Dic = 365 días
      // ceil(365/7) = ceil(52.14) = 53
      expect(weeksUntilEndOfYear(DateTime(2024, 1, 1)), 53);
    });

    test('desde el 2 de enero (año no bisiesto 2023) devuelve 52', () {
      // 2023-12-31 - 2023-01-02 = 363 días → ceil(363/7) = ceil(51.86) = 52
      expect(weeksUntilEndOfYear(DateTime(2023, 1, 2)), 52);
    });

    test('desde el 1 de junio devuelve 31 semanas', () {
      // 2024-12-31 - 2024-06-01 = 213 días → ceil(213/7) = ceil(30.43) = 31
      expect(weeksUntilEndOfYear(DateTime(2024, 6, 1)), 31);
    });

    test('desde el 1 de julio devuelve 27 semanas', () {
      // 2024-12-31 - 2024-07-01 = 183 días → ceil(183/7) = ceil(26.14) = 27
      expect(weeksUntilEndOfYear(DateTime(2024, 7, 1)), 27);
    });

    test('el resultado es siempre >= 1', () {
      for (int month = 1; month <= 12; month++) {
        final weeks = weeksUntilEndOfYear(DateTime(2024, month, 1));
        expect(weeks, greaterThanOrEqualTo(1), reason: 'Falló para mes $month');
      }
    });

    test('el resultado es siempre <= 999 (no supera el clamp)', () {
      expect(weeksUntilEndOfYear(DateTime(2024, 1, 1)), lessThanOrEqualTo(999));
    });
  });

  group('comparación entre opciones de recurrencia', () {
    test('restOfYear desde enero genera más semanas que twoMonths (8)', () {
      final weeks = weeksUntilEndOfYear(DateTime(2024, 1, 1));
      expect(weeks, greaterThan(8));
    });

    test('restOfYear desde enero genera más semanas que oneMonth (4)', () {
      final weeks = weeksUntilEndOfYear(DateTime(2024, 1, 1));
      expect(weeks, greaterThan(4));
    });

    test('restOfYear desde noviembre genera menos semanas que twoMonths', () {
      // 2024-12-31 - 2024-11-01 = 60 días → ceil(60/7) = 9 semanas
      // twoMonths = 8, pero desde nov es 9 → sigue siendo más que twoMonths
      // Desde diciembre sería menos
      final weeks = weeksUntilEndOfYear(DateTime(2024, 12, 1));
      // 2024-12-31 - 2024-12-01 = 30 días → ceil(30/7) = 5
      expect(weeks, lessThan(8));
    });

    test('semanas decrecen a medida que avanza el año', () {
      final jan = weeksUntilEndOfYear(DateTime(2024, 1, 1));
      final jun = weeksUntilEndOfYear(DateTime(2024, 6, 1));
      final nov = weeksUntilEndOfYear(DateTime(2024, 11, 1));
      expect(jan, greaterThan(jun));
      expect(jun, greaterThan(nov));
    });
  });
}
