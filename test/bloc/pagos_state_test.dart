import 'package:flutter_test/flutter_test.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/models/subscription.dart';

Subscription makeSub({
  required String id,
  required String status,
  double price = 1000.0,
  String name = 'Alumno Test',
}) =>
    Subscription(
      id: id,
      studentName: name,
      planName: 'Plan Base',
      price: price,
      currency: 'ARS',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      status: status,
    );

void main() {
  group('PagosLoaded.filteredPayments', () {
    test('sin filtros devuelve todos los pagos', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'pending'),
      ]);
      expect(state.filteredPayments.length, 2);
    });

    test('filtra por un único status', () {
      final state = PagosLoaded(
        payments: [
          makeSub(id: '1', status: 'active'),
          makeSub(id: '2', status: 'pending'),
          makeSub(id: '3', status: 'expired'),
        ],
        selectedStatuses: const {'active'},
      );
      expect(state.filteredPayments.length, 1);
      expect(state.filteredPayments.first.id, '1');
    });

    test('filtra por múltiples statuses (OR)', () {
      final state = PagosLoaded(
        payments: [
          makeSub(id: '1', status: 'active'),
          makeSub(id: '2', status: 'pending'),
          makeSub(id: '3', status: 'expired'),
          makeSub(id: '4', status: 'cancelled'),
        ],
        selectedStatuses: const {'pending', 'expired'},
      );
      expect(state.filteredPayments.length, 2);
      expect(state.filteredPayments.map((p) => p.id), containsAll(['2', '3']));
    });

    test('filtra por searchQuery (nombre, case-insensitive)', () {
      final state = PagosLoaded(
        payments: [
          makeSub(id: '1', status: 'active', name: 'Ana García'),
          makeSub(id: '2', status: 'active', name: 'Luis Pérez'),
        ],
        searchQuery: 'ana',
      );
      expect(state.filteredPayments.length, 1);
      expect(state.filteredPayments.first.id, '1');
    });

    test('aplica status y searchQuery juntos (AND)', () {
      final state = PagosLoaded(
        payments: [
          makeSub(id: '1', status: 'active', name: 'Ana García'),
          makeSub(id: '2', status: 'pending', name: 'Ana López'),
          makeSub(id: '3', status: 'active', name: 'Luis Pérez'),
        ],
        selectedStatuses: const {'active'},
        searchQuery: 'ana',
      );
      expect(state.filteredPayments.length, 1);
      expect(state.filteredPayments.first.id, '1');
    });

    test('searchQuery con solo espacios se ignora', () {
      final state = PagosLoaded(
        payments: [makeSub(id: '1', status: 'active')],
        searchQuery: '   ',
      );
      expect(state.filteredPayments.length, 1);
    });

    test('devuelve vacío cuando ningún pago coincide', () {
      final state = PagosLoaded(
        payments: [makeSub(id: '1', status: 'active', name: 'Luis')],
        searchQuery: 'XYZ_SIN_COINCIDENCIA',
      );
      expect(state.filteredPayments, isEmpty);
    });
  });

  group('PagosLoaded.monthlyRevenue', () {
    test('suma sólo suscripciones activas', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active', price: 1000),
        makeSub(id: '2', status: 'active', price: 2000),
        makeSub(id: '3', status: 'pending', price: 500),
        makeSub(id: '4', status: 'expired', price: 300),
      ]);
      expect(state.monthlyRevenue, 3000.0);
    });

    test('devuelve 0 cuando no hay activos', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'pending', price: 500),
      ]);
      expect(state.monthlyRevenue, 0.0);
    });

    test('devuelve 0 con lista vacía', () {
      expect(PagosLoaded(payments: []).monthlyRevenue, 0.0);
    });
  });

  group('PagosLoaded.outstandingAmount y outstandingCount', () {
    test('outstandingAmount suma pending + expired', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active', price: 1000),
        makeSub(id: '2', status: 'pending', price: 500),
        makeSub(id: '3', status: 'expired', price: 300),
        makeSub(id: '4', status: 'cancelled', price: 200),
      ]);
      expect(state.outstandingAmount, 800.0);
    });

    test('outstandingAmount no incluye cancelled', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'cancelled', price: 999),
      ]);
      expect(state.outstandingAmount, 0.0);
    });

    test('outstandingCount cuenta pending + expired', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'pending'),
        makeSub(id: '3', status: 'expired'),
        makeSub(id: '4', status: 'expired'),
      ]);
      expect(state.outstandingCount, 3);
    });

    test('outstandingCount devuelve 0 cuando no hay deuda', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'cancelled'),
      ]);
      expect(state.outstandingCount, 0);
    });
  });

  group('PagosLoaded.paidSessionsPercentage', () {
    test('devuelve 0 con lista vacía', () {
      expect(PagosLoaded(payments: []).paidSessionsPercentage, 0.0);
    });

    test('devuelve 1.0 cuando todos son activos', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'active'),
      ]);
      expect(state.paidSessionsPercentage, 1.0);
    });

    test('devuelve 0.5 cuando la mitad es activa', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'pending'),
      ]);
      expect(state.paidSessionsPercentage, 0.5);
    });

    test('devuelve 0 cuando ninguno es activo', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'pending'),
        makeSub(id: '2', status: 'expired'),
      ]);
      expect(state.paidSessionsPercentage, 0.0);
    });

    test('el resultado está siempre entre 0 y 1', () {
      final state = PagosLoaded(payments: [
        makeSub(id: '1', status: 'active'),
        makeSub(id: '2', status: 'pending'),
        makeSub(id: '3', status: 'active'),
      ]);
      expect(state.paidSessionsPercentage, inInclusiveRange(0.0, 1.0));
    });
  });

  group('PagosLoaded – paginación', () {
    List<Subscription> makeSubs(int count) =>
        List.generate(count, (i) => makeSub(id: '$i', status: 'active'));

    test('5 pagos = 1 página', () {
      expect(PagosLoaded(payments: makeSubs(5)).totalPages, 1);
    });

    test('6 pagos = 2 páginas', () {
      expect(PagosLoaded(payments: makeSubs(6)).totalPages, 2);
    });

    test('10 pagos = 2 páginas', () {
      expect(PagosLoaded(payments: makeSubs(10)).totalPages, 2);
    });

    test('lista vacía = mínimo 1 página', () {
      expect(PagosLoaded(payments: []).totalPages, 1);
    });

    test('pagePayments devuelve los primeros 5 en página 1', () {
      final state = PagosLoaded(payments: makeSubs(7));
      expect(state.pagePayments.length, 5);
      expect(state.pagePayments.first.id, '0');
    });

    test('pagePayments devuelve los sobrantes en la última página', () {
      final state = PagosLoaded(payments: makeSubs(7), currentPage: 2);
      expect(state.pagePayments.length, 2);
    });

    test('pagePayments devuelve vacío cuando no hay pagos', () {
      expect(PagosLoaded(payments: []).pagePayments, isEmpty);
    });
  });

  group('PagosLoaded.copyWith y copyWithPage', () {
    test('copyWith actualiza sólo los campos especificados', () {
      final original = PagosLoaded(
        payments: [makeSub(id: '1', status: 'active')],
        currentPage: 1,
        searchQuery: 'test',
      );
      final updated = original.copyWith(currentPage: 3);
      expect(updated.currentPage, 3);
      expect(updated.searchQuery, 'test');
      expect(updated.payments.length, 1);
    });

    test('copyWith preserva selectedStatuses', () {
      final original = PagosLoaded(
        payments: [],
        selectedStatuses: const {'active', 'pending'},
      );
      final updated = original.copyWith(searchQuery: 'nuevo');
      expect(updated.selectedStatuses, {'active', 'pending'});
    });

    test('copyWithPage cambia sólo la página', () {
      final original = PagosLoaded(
        payments: [makeSub(id: '1', status: 'active')],
        searchQuery: 'query',
        selectedStatuses: const {'active'},
      );
      final paged = original.copyWithPage(2);
      expect(paged.currentPage, 2);
      expect(paged.searchQuery, 'query');
      expect(paged.selectedStatuses, {'active'});
    });
  });
}
