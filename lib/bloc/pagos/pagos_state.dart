part of 'pagos_bloc.dart';

abstract class PagosState {}

/// Estado inicial antes de solicitar la carga.
class PagosInitial extends PagosState {}

class PagosLoading extends PagosState {}

/// Datos cargados y listos para mostrar.
class PagosLoaded extends PagosState {
  final List<Subscription> payments;
  final int currentPage;
  static const int perPage = 5;

  PagosLoaded({required this.payments, this.currentPage = 1});

  int get totalPages =>
      (payments.length / perPage).ceil().clamp(1, 999);

  List<Subscription> get pagePayments {
    if (payments.isEmpty) return [];
    final start = (currentPage - 1) * perPage;
    final end = (start + perPage).clamp(0, payments.length);
    return payments.sublist(start, end);
  }

  /// Ingresos mensuales (suma de precios de suscripciones activas)
  double get monthlyRevenue {
    return payments
        .where((p) => p.status == 'active')
        .fold(0.0, (sum, p) => sum + p.price);
  }

  /// Monto pendiente (suma de precios de suscripciones pendientes o vencidas)
  double get outstandingAmount {
    return payments
        .where((p) => p.status == 'pending' || p.status == 'expired')
        .fold(0.0, (sum, p) => sum + p.price);
  }

  /// Cantidad de facturas pendientes
  int get outstandingCount {
    return payments
        .where((p) => p.status == 'pending' || p.status == 'expired')
        .length;
  }

  /// Porcentaje de sesiones pagadas (activas / total)
  double get paidSessionsPercentage {
    if (payments.isEmpty) return 0.0;
    final activeCount = payments.where((p) => p.status == 'active').length;
    return activeCount / payments.length;
  }

  /// Crea una copia con la página actualizada (sin recargar datos).
  PagosLoaded copyWithPage(int page) =>
      PagosLoaded(payments: payments, currentPage: page);
}
