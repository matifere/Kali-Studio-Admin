import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/models/subscription.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/pagos/assign_plan_dialog.dart';

/// Barra de filtros y acciones de la sección de pagos.
class PagosFilters extends StatelessWidget {
  const PagosFilters({super.key});

  void _toggleStatus(
      BuildContext context, Set<String> current, String status, bool add) {
    final newSet = Set<String>.from(current);
    if (add) {
      newSet.add(status);
    } else {
      newSet.remove(status);
    }
    context.read<PagosBloc>().add(PagosFiltersChanged(newSet));
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocBuilder<PagosBloc, PagosState>(
      builder: (context, state) {
        Set<String> selectedStatuses = {};
        if (state is PagosLoaded) {
          selectedStatuses = state.selectedStatuses;
        }

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                // Búsqueda
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUSCAR USUARIO',
                        style: kaliColors.label(
                          kaliColors.espresso.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          onChanged: (value) {
                            context
                                .read<PagosBloc>()
                                .add(PagosSearchChanged(value));
                          },
                          style: kaliColors.body(kaliColors.espresso, size: 14),
                          decoration: InputDecoration(
                            hintText: 'Ej. Juan Pérez',
                            hintStyle: kaliColors.body(
                              kaliColors.espresso.withValues(alpha: 0.4),
                              size: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: kaliColors.espresso.withValues(alpha: 0.4),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            filled: true,
                            fillColor: kaliColors.warmWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color:
                                    kaliColors.espresso.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color:
                                    kaliColors.espresso.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: kaliColors.espresso,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO',
                      style: kaliColors.label(
                        kaliColors.espresso.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(
                          label: 'Activo',
                          isSelected: selectedStatuses.contains('active'),
                          onToggle: (selected) => _toggleStatus(
                              context, selectedStatuses, 'active', selected),
                        ),
                        _StatusChip(
                          label: 'Pendiente',
                          isSelected: selectedStatuses.contains('pending'),
                          onToggle: (selected) => _toggleStatus(
                              context, selectedStatuses, 'pending', selected),
                        ),
                        _StatusChip(
                          label: 'Vencido',
                          isSelected: selectedStatuses.contains('expired'),
                          onToggle: (selected) => _toggleStatus(
                              context, selectedStatuses, 'expired', selected),
                        ),
                        _StatusChip(
                          label: 'Cancelado',
                          isSelected: selectedStatuses.contains('cancelled'),
                          onToggle: (selected) => _toggleStatus(
                              context, selectedStatuses, 'cancelled', selected),
                        ),
                        if (selectedStatuses.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              context
                                  .read<PagosBloc>()
                                  .add(PagosFiltersChanged(const {}));
                            },
                            icon: Icon(Icons.clear,
                                size: 16,
                                color:
                                    kaliColors.espresso.withValues(alpha: 0.65)),
                            label: Text(
                              'Limpiar',
                              style: kaliColors.body(
                                  kaliColors.espresso.withValues(alpha: 0.65),
                                  size: 13,
                                  weight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Botones de acción
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OutlinedActionBtn(
                  icon: Icons.download_rounded,
                  label: 'Exportar a Excel',
                  onTap: () {
                    if (state is PagosLoaded) {
                      _exportReport(context, state.filteredPayments);
                    }
                  },
                ),
                _FilledActionBtn(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Asignar Plan',
                  onTap: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const AssignPlanDialog(),
                    );
                    if (result == true && context.mounted) {
                      context.read<PagosBloc>().add(PagosLoadRequested());
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportReport(
      BuildContext context, List<Subscription> payments) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      final headerStyle = CellStyle(bold: true);
      final headers = [
        'Alumno',
        'Plan',
        'Monto',
        'Moneda',
        'Fecha Inicio',
        'Fecha Fin',
        'Estado',
      ];
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      for (var p in payments) {
        sheet.appendRow([
          TextCellValue(p.studentName),
          TextCellValue(p.planName),
          DoubleCellValue(p.price),
          TextCellValue(p.currency),
          TextCellValue(p.startDateFormatted),
          TextCellValue(p.endDateFormatted),
          TextCellValue(p.statusLabel),
        ]);
      }

      final encoded = excel.encode();
      if (encoded == null) throw Exception('No se pudo generar el Excel');

      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FileSaver.instance.saveFile(
        name: 'reporte_pagos_$fecha',
        bytes: Uint8List.fromList(encoded),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte exportado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo exportar el archivo. Intentá nuevamente.')),
        );
      }
    }
  }
}

// ─── Chip de estado ───────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onToggle;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return FilterChip(
      label: Text(
        label,
        style: kaliColors.body(
          isSelected ? kaliColors.warmWhite : kaliColors.espresso,
          weight: FontWeight.w500,
          size: 13,
        ),
      ),
      selected: isSelected,
      onSelected: onToggle,
      selectedColor: kaliColors.espresso,
      backgroundColor: kaliColors.warmWhite,
      checkmarkColor: kaliColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? kaliColors.espresso
              : kaliColors.espresso.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

// ─── Botón de acción con borde ────────────────────────────────────────────────
class _OutlinedActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OutlinedActionBtn(
      {required this.icon, required this.label, this.onTap});

  @override
  State<_OutlinedActionBtn> createState() => _OutlinedActionBtnState();
}

class _OutlinedActionBtnState extends State<_OutlinedActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? kaliColors.sand : kaliColors.warmWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: kaliColors.espresso.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: kaliColors.espresso),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: kaliColors.body(
                  kaliColors.espresso,
                  weight: FontWeight.w600,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón de acción relleno ──────────────────────────────────────────────────
class _FilledActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FilledActionBtn({required this.icon, required this.label, this.onTap});

  @override
  State<_FilledActionBtn> createState() => _FilledActionBtnState();
}

class _FilledActionBtnState extends State<_FilledActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? kaliColors.espressoL : kaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: kaliColors.espresso.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: kaliColors.warmWhite),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: kaliColors.body(
                  kaliColors.warmWhite,
                  weight: FontWeight.w600,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
