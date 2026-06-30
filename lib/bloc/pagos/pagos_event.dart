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

/// El usuario editó la asignación de un plan (plan y/o fechas).
class PagosSubscriptionEdited extends PagosEvent {
  final String subscriptionId;
  final String planId;
  final String planName;
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;

  PagosSubscriptionEdited({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.price,
    required this.currency,
    required this.startDate,
    required this.endDate,
  });
}

/// El usuario eliminó por completo la asignación de un plan.
class PagosSubscriptionDeleted extends PagosEvent {
  final String subscriptionId;

  PagosSubscriptionDeleted(this.subscriptionId);
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
