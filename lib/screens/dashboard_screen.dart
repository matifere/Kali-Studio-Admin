import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/bloc/navigation/navigation_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/sidebar.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/dashboard/stat_cards.dart';
import 'package:kali_studio/widgets/dashboard/schedule_list.dart';
import 'package:kali_studio/widgets/dashboard/recent_activity.dart';
import 'package:kali_studio/screens/alumnos_screen.dart';
import 'package:kali_studio/screens/turnos_screen.dart';
import 'package:kali_studio/screens/pagos_screen.dart';
import 'package:kali_studio/bloc/dashboard/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _buildCurrentPage(String page) {
    switch (page) {
      case 'Alumnos':
        return const AlumnosScreen();
      case 'Turnos':
        return const TurnosScreen();
      case 'Pagos':
        return const PagosScreen();
      default:
        return const _DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          backgroundColor: KaliColors.warmWhite,
          body: Row(
            children: [
              DashboardSidebar(
                currentPage: navState.currentPage,
                onNavigate: (page) {
                  context.read<NavigationBloc>().add(
                        NavigationPageChanged(page),
                      );
                },
              ),
              Expanded(child: _buildCurrentPage(navState.currentPage)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Dashboard home content ───────────────────────────────────────────────────
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

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
                Text(
                  'Buenos días,',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto es lo que está pasando en Kali Studio hoy.',
                  style: KaliText.body(
                    KaliColors.espresso.withOpacity(0.6),
                    size: 16,
                  ),
                ),
                const SizedBox(height: 40),
                const DashboardStatCards(),
                const SizedBox(height: 32),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: DashboardScheduleList()),
                    SizedBox(width: 24),
                    Expanded(flex: 4, child: DashboardRecentActivity()),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
