import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class AlumnosFilterDialog extends StatefulWidget {
  final AlumnosLoaded state;

  const AlumnosFilterDialog({super.key, required this.state});

  @override
  State<AlumnosFilterDialog> createState() => _AlumnosFilterDialogState();
}

class _AlumnosFilterDialogState extends State<AlumnosFilterDialog> {
  String? _selectedPatologia;
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _selectedPatologia = widget.state.patologiaFilter;
    _isActive = widget.state.isActiveFilter;
  }

  void _applyFilters() {
    context.read<AlumnosBloc>().add(
          AlumnosFilterChanged(
            // Preserva la búsqueda de texto actual
            searchQuery: widget.state.searchQuery,
            patologiaFilter: _selectedPatologia,
            isActiveFilter: _isActive,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    context.read<AlumnosBloc>().add(
          AlumnosFilterChanged(
            searchQuery: widget.state.searchQuery,
            patologiaFilter: null,
            isActiveFilter: null,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final hasActiveFilters = _selectedPatologia != null || _isActive != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kaliColors.warmWhite,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar Alumnos',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: kaliColors.espresso,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: kaliColors.espresso),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aplica filtros para encontrar alumnos específicos.',
              style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            // Filtro de Estado
            Text('Estado del Alumno', style: KaliText.label(kaliColors.espresso)),
            const SizedBox(height: 8),
            _buildDropdown<bool?>(
              value: _isActive,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los estados')),
                DropdownMenuItem(value: true, child: Text('Activos')),
                DropdownMenuItem(value: false, child: Text('Inactivos')),
              ],
              onChanged: (val) => setState(() => _isActive = val),
              kaliColors: kaliColors,
            ),
            const SizedBox(height: 24),

            // Filtro de Patología
            Text('Patología', style: KaliText.label(kaliColors.espresso)),
            const SizedBox(height: 8),
            widget.state.availablePatologias.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No hay patologías registradas aún.',
                      style: KaliText.body(
                        kaliColors.espresso.withValues(alpha: 0.45),
                        size: 13,
                      ),
                    ),
                  )
                : _buildDropdown<String?>(
                    value: _selectedPatologia,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Cualquier patología')),
                      ...widget.state.availablePatologias.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedPatologia = val),
                    kaliColors: kaliColors,
                  ),
            const SizedBox(height: 40),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Limpiar filtros',
                      style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                  ),
                if (hasActiveFilters) const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _applyFilters,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: kaliColors.espresso,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Aplicar',
                        style: KaliText.body(kaliColors.warmWhite,
                            weight: FontWeight.w600, size: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required KaliColorsExtension kaliColors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kaliColors.sand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kaliColors.sand2, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kaliColors.clayDark),
          dropdownColor: kaliColors.warmWhite,
          style: KaliText.body(kaliColors.espresso, size: 14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
