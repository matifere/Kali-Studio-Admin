import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/pagos/pagos_stat_cards.dart';
import 'package:kali_studio/widgets/pagos/pagos_filters.dart';
import 'package:kali_studio/widgets/pagos/pagos_table.dart';
import 'package:kali_studio/widgets/pagos/pagos_bottom_panels.dart';

/// Pantalla principal de Pagos.
class PagosScreen extends StatelessWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Pagos',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Historial de cobros y transacciones del estudio.',
                  style: KaliText.body(
                    KaliColors.espresso.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Tarjetas de estadísticas
                const PagosStatCards(),
                const SizedBox(height: 32),

                // Filtros + acciones
                const PagosFilters(),
                const SizedBox(height: 24),

                // Tabla de transacciones
                const PagosTable(),
                const SizedBox(height: 32),

                // Paneles inferiores
                const PagosBottomPanels(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
