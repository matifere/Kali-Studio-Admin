import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/pagos/pagos_stat_cards.dart';
import 'package:kali_studio/widgets/pagos/pagos_filters.dart';
import 'package:kali_studio/widgets/pagos/pagos_table.dart';
import 'package:kali_studio/widgets/pagos/plans_table.dart';

/// Pantalla principal de Pagos.
class PagosScreen extends StatelessWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Pagos',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isSmall ? 36 : 46,
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

                // Tabla de planes disponibles
                const PlansTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

