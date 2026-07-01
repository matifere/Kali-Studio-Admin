// Mocks puros sin UI
import 'package:argrity/models/payment.dart';

/// Datos de ejemplo de pagos para desarrollo.
const List<Payment> kMockPayments = [
  // ── Página 1 ──
  Payment(
    studentInitials: 'AM',
    studentName: 'Alessandra Moretti',
    reference: 'INV-2024-089',
    date: '15 Mar 2024',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.completed,
    amount: 18000,
  ),
  Payment(
    studentInitials: 'JR',
    studentName: 'Julián Rinaldi',
    reference: 'INV-2024-092',
    date: '14 Mar 2024',
    method: PaymentMethod.bankTransfer,
    status: PaymentStatus.pending,
    amount: 12000,
  ),
  Payment(
    studentInitials: 'SV',
    studentName: 'Sofía Valenti',
    reference: 'INV-2024-077',
    date: '12 Mar 2024',
    method: PaymentMethod.cash,
    status: PaymentStatus.completed,
    amount: 24000,
  ),
  Payment(
    studentInitials: 'MB',
    studentName: 'Marco Bianchi',
    reference: 'INV-2024-041',
    date: '05 Mar 2024',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.overdue,
    amount: 18000,
  ),
  Payment(
    studentInitials: 'LD',
    studentName: 'Luca De Luca',
    reference: 'INV-2024-099',
    date: '02 Mar 2024',
    method: PaymentMethod.bankTransfer,
    status: PaymentStatus.completed,
    amount: 35000,
  ),
  // ── Página 2 ──
  Payment(
    studentInitials: 'CR',
    studentName: 'Camila Rossi',
    reference: 'INV-2024-038',
    date: '28 Feb 2024',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.completed,
    amount: 18000,
  ),
  Payment(
    studentInitials: 'FT',
    studentName: 'Federico Torres',
    reference: 'INV-2024-035',
    date: '25 Feb 2024',
    method: PaymentMethod.cash,
    status: PaymentStatus.completed,
    amount: 12000,
  ),
  Payment(
    studentInitials: 'VP',
    studentName: 'Valentina Paredes',
    reference: 'INV-2024-031',
    date: '22 Feb 2024',
    method: PaymentMethod.bankTransfer,
    status: PaymentStatus.pending,
    amount: 24000,
  ),
  Payment(
    studentInitials: 'NL',
    studentName: 'Nicolás López',
    reference: 'INV-2024-028',
    date: '20 Feb 2024',
    method: PaymentMethod.creditCard,
    status: PaymentStatus.completed,
    amount: 18000,
  ),
  Payment(
    studentInitials: 'IG',
    studentName: 'Isabella García',
    reference: 'INV-2024-025',
    date: '18 Feb 2024',
    method: PaymentMethod.cash,
    status: PaymentStatus.completed,
    amount: 12000,
  ),
];

/// Entradas de ejemplo del libro contable.
const List<LedgerEntry> kMockLedgerEntries = [
  LedgerEntry(
    timestamp: 'HOY, 09:42 AM',
    description: 'Pago recibido de Sofía Valenti (Efectivo)',
  ),
  LedgerEntry(
    timestamp: 'AYER, 06:15 PM',
    description: 'Factura #INV-041 marcada como Vencida',
    isAlert: true,
  ),
  LedgerEntry(
    timestamp: '14 MAR, 11:20 AM',
    description: 'Procesamiento por lotes completado para planes mensuales',
  ),
];
