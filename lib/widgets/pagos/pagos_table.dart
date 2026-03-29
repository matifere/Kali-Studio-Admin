import 'package:flutter/material.dart';
import 'package:kali_studio/data/mock_payments.dart';
import 'package:kali_studio/models/payment.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/kali_empty_state.dart';
import 'package:kali_studio/widgets/common/kali_pagination.dart';
import 'package:kali_studio/widgets/pagos/payment_row.dart';

/// Tabla paginada de transacciones.
class PagosTable extends StatefulWidget {
  final List<Payment> payments;

  const PagosTable({
    super.key,
    this.payments = kMockPayments,
  });

  @override
  State<PagosTable> createState() => _PagosTableState();
}

class _PagosTableState extends State<PagosTable> {
  int _currentPage = 1;
  static const int _perPage = 5;

  int get _totalPayments => widget.payments.length;
  int get _totalPages => (_totalPayments / _perPage).ceil().clamp(1, 999);

  List<Payment> get _pagePayments {
    if (widget.payments.isEmpty) return [];
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _totalPayments);
    return widget.payments.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final payments = _pagePayments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.payments.isEmpty)
            const KaliEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No hay transacciones registradas',
              subtitle:
                  'Las transacciones aparecerán aquí cuando registres pagos.',
            )
          else ...[
            _buildColumnHeaders(),
            ...payments.map((p) => PaymentRow(payment: p)),
            KaliPagination(
              currentPage: _currentPage,
              totalPages: _totalPages,
              showingCount: payments.length,
              totalCount: _totalPayments,
              itemLabel: 'TRANSACCIONES',
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    final style =
        KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('ALUMNO', style: style)),
          Expanded(flex: 3, child: Text('REFERENCIA', style: style)),
          Expanded(flex: 2, child: Text('FECHA', style: style)),
          Expanded(flex: 3, child: Text('MÉTODO', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(
            flex: 2,
            child: Text('MONTO', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
