import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';

class AlumnosFilterDialog extends StatefulWidget {
  final AlumnosLoaded state;

  const AlumnosFilterDialog({super.key, required this.state});

  @override
  State<AlumnosFilterDialog> createState() => _AlumnosFilterDialogState();
}

class _AlumnosFilterDialogState extends State<AlumnosFilterDialog> {
  late final TextEditingController _searchController;
  String? _selectedPlan;
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _selectedPlan = widget.state.planFilter;
    _isActive = widget.state.isActiveFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AlumnosBloc>().add(
          AlumnosFilterChanged(
            searchQuery: _searchController.text,
            planFilter: _selectedPlan,
            isActiveFilter: _isActive,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    context.read<AlumnosBloc>().add(
          AlumnosFilterChanged(
            searchQuery: '',
            planFilter: null,
            isActiveFilter: null,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: KaliColors.warmWhite,
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
                    color: KaliColors.espresso,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: KaliColors.espresso),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aplica filtros para encontrar alumnos específicos.',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            // Búsqueda por texto
            KaliTextField(
              controller: _searchController,
              label: 'Buscar',
              hint: 'Nombre o correo electrónico',
              suffixIcon: Icons.search,
            ),
            const SizedBox(height: 24),

            // Filtro de Estado
            Text('Estado del Alumno', style: KaliText.label(KaliColors.espresso)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: KaliColors.sand,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KaliColors.sand2, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool?>(
                  value: _isActive,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KaliColors.clayDark),
                  dropdownColor: KaliColors.warmWhite,
                  style: KaliText.body(KaliColors.espresso, size: 14),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos los estados')),
                    DropdownMenuItem(value: true, child: Text('Activos')),
                    DropdownMenuItem(value: false, child: Text('Inactivos')),
                  ],
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filtro de Plan
            Text('Plan', style: KaliText.label(KaliColors.espresso)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: KaliColors.sand,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KaliColors.sand2, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedPlan,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KaliColors.clayDark),
                  dropdownColor: KaliColors.warmWhite,
                  style: KaliText.body(KaliColors.espresso, size: 14),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Cualquier plan')),
                    ...widget.state.availablePlans.map(
                      (plan) => DropdownMenuItem(value: plan, child: Text(plan)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedPlan = val),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Limpiar',
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _applyFilters,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: KaliColors.espresso,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Aplicar Filtros',
                        style: KaliText.body(KaliColors.warmWhite, weight: FontWeight.w600, size: 13),
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
}
