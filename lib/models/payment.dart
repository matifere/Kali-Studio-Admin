import 'package:flutter/material.dart';

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
  final Color avatarColor;
  final String studentName;
  final String reference;
  final String date;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;

  const Payment({
    required this.studentInitials,
    required this.avatarColor,
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

  /// Color del badge de estado.
  Color get statusColor {
    switch (status) {
      case PaymentStatus.completed:
        return const Color(0xFF5C9E6C);
      case PaymentStatus.pending:
        return const Color(0xFFD4A836);
      case PaymentStatus.overdue:
        return const Color(0xFFD4685C);
    }
  }

  /// Color de fondo del badge de estado.
  Color get statusBgColor {
    switch (status) {
      case PaymentStatus.completed:
        return const Color(0xFFE8F5E9);
      case PaymentStatus.pending:
        return const Color(0xFFFFF8E1);
      case PaymentStatus.overdue:
        return const Color(0xFFFDECEA);
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
