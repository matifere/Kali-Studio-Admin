// Modelo puro, sin dependencias de UI

/// Estado de un pago.
enum PaymentStatus {
  completed,
  pending,
  overdue,
}

/// Método de pago.
enum PaymentMethod {
  creditCard,
  bankTransfer,
  cash,
}

/// Modelo de datos de un pago/transacción.
class Payment {
  final String studentInitials;
  final String studentName;
  final String reference;
  final String date;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;

  const Payment({
    required this.studentInitials,
    required this.studentName,
    required this.reference,
    required this.date,
    required this.method,
    required this.status,
    required this.amount,
  });

  /// Texto legible del método de pago.
  String get methodLabel {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia';
      case PaymentMethod.cash:
        return 'Efectivo';
    }
  }

  /// Texto legible del estado.
  String get statusLabel {
    switch (status) {
      case PaymentStatus.completed:
        return 'COMPLETADO';
      case PaymentStatus.pending:
        return 'PENDIENTE';
      case PaymentStatus.overdue:
        return 'VENCIDO';
    }
  }

  /// Monto formateado.
  String get amountFormatted => '\$${amount.toStringAsFixed(2)}';
}

/// Entrada del libro contable / actividad financiera.
class LedgerEntry {
  final String timestamp;
  final String description;
  final bool isAlert;

  const LedgerEntry({
    required this.timestamp,
    required this.description,
    this.isAlert = false,
  });
}
