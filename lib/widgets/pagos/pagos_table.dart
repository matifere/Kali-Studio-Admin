import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/kali_empty_state.dart';
import 'package:argrity/widgets/common/kali_pagination.dart';
import 'package:argrity/widgets/pagos/subscription_row.dart';

/// Tabla paginada de transacciones.
///
/// Consume [PagosBloc] para los datos y la paginación.
/// No tiene estado propio — es un [StatelessWidget] puro.
class PagosTable extends StatelessWidget {
  const PagosTable({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
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
                      icon: Icons.card_membership_rounded,
                      title: 'No hay suscripciones registradas',
                      subtitle:
                          'Las suscripciones a planes aparecerán aquí.',
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double minWidth = 780.0;
                        final tableRows = Column(
                          children: [
                            _buildColumnHeaders(kaliColors),
                            ...state.pagePayments.map((p) => SubscriptionRow(subscription: p)),
                          ],
                        );
                        if (constraints.maxWidth < minWidth) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: minWidth, child: tableRows),
                          );
                        }
                        return tableRows;
                      },
                    ),
                    KaliPagination(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      showingCount: state.pagePayments.length,
                      totalCount: state.payments.length,
                      itemLabel: 'SUSCRIPCIONES',
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
  Widget _buildColumnHeaders(KaliColorsExtension kaliColors) {
    final style = KaliText.label(kaliColors.espresso.withValues(alpha: 0.45));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('ALUMNO', style: style)),
          Expanded(flex: 3, child: Text('PLAN', style: style)),
          Expanded(flex: 2, child: Text('FECHAS', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(
            flex: 2,
            child: Text('PRECIO', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('ACCIONES', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
