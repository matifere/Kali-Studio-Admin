import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/bloc/pagos/pagos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/pagos/pagos_stat_cards.dart';
import 'package:kali_studio/widgets/pagos/pagos_filters.dart';
import 'package:kali_studio/widgets/pagos/pagos_table.dart';
import 'package:kali_studio/widgets/pagos/plans_table.dart';
import 'package:kali_studio/widgets/pagos/saas_subscription_view.dart';

/// Pantalla principal de Pagos.
class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

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
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const DashboardTopNavBar(),
          Expanded(
            child: Padding(
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
                  const SizedBox(height: 24),
                  
                  // TabBar
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: KaliColors.clay, width: 2),
                      ),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: KaliColors.espresso,
                      indicatorWeight: 3,
                      labelColor: KaliColors.espresso,
                      unselectedLabelColor: KaliColors.clayDark,
                      labelStyle: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                      unselectedLabelStyle: KaliText.body(KaliColors.clayDark, weight: FontWeight.w500),
                      overlayColor: const WidgetStatePropertyAll(Color(0x4DF4EBE1)), // KaliColors.sand.withValues(alpha: 0.3)
                      tabs: const [
                        Tab(text: 'Alumnos'),
                        Tab(text: 'Suscripción de Software'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TabViews
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Pestaña 1: Alumnos
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              PagosStatCards(),
                              SizedBox(height: 32),
                              PagosFilters(),
                              SizedBox(height: 24),
                              PagosTable(),
                              SizedBox(height: 32),
                              PlansTable(),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                        // Pestaña 2: Software
                        const SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 40.0),
                            child: SaasSubscriptionView(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

