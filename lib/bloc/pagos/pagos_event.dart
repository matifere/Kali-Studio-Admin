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
