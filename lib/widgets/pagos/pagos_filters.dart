import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/models/subscription.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/pagos/create_plan_dialog.dart';
import 'package:kali_studio/widgets/pagos/assign_plan_dialog.dart';

/// Barra de filtros y acciones de la sección de pagos.
class PagosFilters extends StatelessWidget {
  const PagosFilters({super.key});

  void _toggleStatus(BuildContext context, Set<String> current, String status, bool add) {
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
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUSCAR USUARIO',
                        style: KaliText.label(
                          KaliColors.espresso.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          onChanged: (value) {
                            context.read<PagosBloc>().add(PagosSearchChanged(value));
                          },
                          style: KaliText.body(KaliColors.espresso, size: 14),
                          decoration: InputDecoration(
                            hintText: 'Ej. Juan Pérez',
                            hintStyle: KaliText.body(
                              KaliColors.espresso.withValues(alpha: 0.4),
                              size: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: KaliColors.espresso.withValues(alpha: 0.4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: KaliColors.espresso.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: KaliColors.espresso.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: KaliColors.espresso,
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
                      style: KaliText.label(
                        KaliColors.espresso.withValues(alpha: 0.45),
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
                          onToggle: (selected) => _toggleStatus(context, selectedStatuses, 'active', selected),
                        ),
                        _StatusChip(
                          label: 'Pendiente',
                          isSelected: selectedStatuses.contains('pending'),
                          onToggle: (selected) => _toggleStatus(context, selectedStatuses, 'pending', selected),
                        ),
                        _StatusChip(
                          label: 'Vencido',
                          isSelected: selectedStatuses.contains('expired'),
                          onToggle: (selected) => _toggleStatus(context, selectedStatuses, 'expired', selected),
                        ),
                        _StatusChip(
                          label: 'Cancelado',
                          isSelected: selectedStatuses.contains('cancelled'),
                          onToggle: (selected) => _toggleStatus(context, selectedStatuses, 'cancelled', selected),
                        ),
                        if (selectedStatuses.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              context.read<PagosBloc>().add(PagosFiltersChanged(const {}));
                            },
                            icon: Icon(Icons.clear, size: 16, color: KaliColors.espresso.withValues(alpha: 0.5)),
                            label: Text(
                              'Limpiar',
                              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5), size: 13, weight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  label: 'Exportar Reporte',
                  onTap: () {
                    if (state is PagosLoaded) {
                      _exportReport(context, state.filteredPayments);
                    }
                  },
                ),
                _FilledActionBtn(
                  icon: Icons.add_card_rounded,
                  label: 'Crear Plan',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreatePlanDialog(),
                    );
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

  Future<void> _exportReport(BuildContext context, List<Subscription> payments) async {
    try {
      List<List<dynamic>> rows = [
        ['ID', 'Alumno', 'Plan', 'Monto', 'Moneda', 'Fecha Inicio', 'Fecha Fin', 'Estado']
      ];

      for (var p in payments) {
        rows.add([
          p.id,
          p.studentName,
          p.planName,
          p.price,
          p.currency,
          p.startDateFormatted,
          p.endDateFormatted,
          p.statusLabel,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      Uint8List bytes = Uint8List.fromList(csv.codeUnits);

      await FileSaver.instance.saveFile(
        name: 'reporte_pagos_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte exportado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
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
    return FilterChip(
      label: Text(
        label,
        style: KaliText.body(
          isSelected ? Colors.white : KaliColors.espresso,
          weight: FontWeight.w500,
          size: 13,
        ),
      ),
      selected: isSelected,
      onSelected: onToggle,
      selectedColor: KaliColors.espresso,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? KaliColors.espresso : KaliColors.espresso.withValues(alpha: 0.1),
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

  const _OutlinedActionBtn({required this.icon, required this.label, this.onTap});

  @override
  State<_OutlinedActionBtn> createState() => _OutlinedActionBtnState();
}

class _OutlinedActionBtnState extends State<_OutlinedActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.sand : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: KaliColors.espresso.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: KaliColors.espresso),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: KaliText.body(
                  KaliColors.espresso,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.espressoL : KaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: KaliColors.espresso.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: KaliColors.warmWhite),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: KaliText.body(
                  KaliColors.warmWhite,
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
