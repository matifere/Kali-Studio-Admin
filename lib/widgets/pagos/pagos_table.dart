import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/kali_empty_state.dart';
import 'package:kali_studio/widgets/common/kali_pagination.dart';
import 'package:kali_studio/widgets/pagos/payment_row.dart';

/// Tabla paginada de transacciones.
///
/// Consume [PagosBloc] para los datos y la paginación.
/// No tiene estado propio — es un [StatelessWidget] puro.
class PagosTable extends StatelessWidget {
  const PagosTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagosBloc, PagosState>(
      builder: (context, state) {
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
          child: switch (state) {
            // ── Datos listos ───────────────────────────────────────────────
            PagosLoaded() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.payments.isEmpty)
                    const KaliEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No hay transacciones registradas',
                      subtitle:
                          'Las transacciones aparecerán aquí cuando registres pagos.',
                    )
                  else ...[
                    _buildColumnHeaders(),
                    ...state.pagePayments.map((p) => PaymentRow(payment: p)),
                    KaliPagination(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      showingCount: state.pagePayments.length,
                      totalCount: state.payments.length,
                      itemLabel: 'TRANSACCIONES',
                      onPageChanged: (page) {
                        context
                            .read<PagosBloc>()
                            .add(PagosPageChanged(page));
                      },
                    ),
                  ],
                ],
              ),

            // ── Estado inicial / inesperado ────────────────────────────────
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  // ── Encabezados de columna ─────────────────────────────────────────────────
  Widget _buildColumnHeaders() {
    final style = KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));

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
