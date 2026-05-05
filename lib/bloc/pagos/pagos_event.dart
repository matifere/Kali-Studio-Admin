part of 'pagos_bloc.dart';

abstract class PagosEvent {}

/// Solicita la carga inicial de pagos.
class PagosLoadRequested extends PagosEvent {}

/// El usuario cambió de página en la tabla de transacciones.
class PagosPageChanged extends PagosEvent {
  final int page;

  PagosPageChanged(this.page);
}

/// El usuario cambió el estado de una suscripción.
class PagosSubscriptionStatusChanged extends PagosEvent {
  final String subscriptionId;
  final String newStatus;

  PagosSubscriptionStatusChanged({
    required this.subscriptionId,
    required this.newStatus,
  });
}

/// El usuario cambió los filtros de estado.
class PagosFiltersChanged extends PagosEvent {
  final Set<String> selectedStatuses;

  PagosFiltersChanged(this.selectedStatuses);
}

/// El usuario cambió el término de búsqueda.
class PagosSearchChanged extends PagosEvent {
  final String query;

  PagosSearchChanged(this.query);
}
