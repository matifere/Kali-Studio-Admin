import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/pagos/pagos_stat_cards.dart';
import 'package:argrity/widgets/pagos/pagos_filters.dart';
import 'package:argrity/widgets/pagos/pagos_table.dart';
import 'package:argrity/widgets/pagos/plans_table.dart';

/// Vistas de la sección Pagos: cobros de alumnos o catálogo de planes.
enum PagosView { alumnos, planes }

/// Pantalla principal de Pagos.
class PagosScreen extends StatefulWidget {
  final PagosView view;

  const PagosScreen({super.key, this.view = PagosView.alumnos});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PagosBloc>().add(PagosLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final bool isPlanes = widget.view == PagosView.planes;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AutoSizeText(isPlanes ? 'Planes' : 'Pagos',
                    style: kaliColors
                        .heading(kaliColors.espresso, size: isSmall ? 36 : 46)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1),
                const SizedBox(height: 4),
                Text(
                  isPlanes
                      ? 'Creá y administrá los planes de tu institución.'
                      : 'Historial de cobros y asignación de planes a alumnos.',
                  style: kaliColors.body(
                    kaliColors.espresso.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    child: isPlanes
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlansTable(),
                              SizedBox(height: 40),
                            ],
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PagosStatCards(),
                              SizedBox(height: 32),
                              PagosFilters(),
                              SizedBox(height: 24),
                              PagosTable(),
                              SizedBox(height: 40),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
