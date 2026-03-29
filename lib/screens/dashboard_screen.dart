import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/sidebar.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/dashboard/stat_cards.dart';
import 'package:kali_studio/widgets/dashboard/schedule_list.dart';
import 'package:kali_studio/widgets/dashboard/recent_activity.dart';
import 'package:kali_studio/widgets/dashboard/bottom_promos.dart';
import 'package:kali_studio/screens/alumnos_screen.dart';
import 'package:kali_studio/screens/turnos_screen.dart';

enum _NavPage { dashboard, alumnos, turnos, pagos }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _NavPage _currentPage = _NavPage.dashboard;

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case _NavPage.dashboard:
        return _DashboardHome();
      case _NavPage.alumnos:
        return const AlumnosScreen();
      case _NavPage.turnos:
        return const TurnosScreen();
      case _NavPage.pagos:
        return const _PlaceholderPage(
          title: 'Pagos',
          subtitle: 'Historial y cobros del estudio.',
          icon: Icons.payment_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: Row(
        children: [
          DashboardSidebar(
            currentPage: _currentPage == _NavPage.dashboard
                ? 'Panel'
                : _currentPage == _NavPage.alumnos
                    ? 'Alumnos'
                    : _currentPage == _NavPage.turnos
                        ? 'Turnos'
                        : 'Pagos',
            onNavigate: (page) {
              setState(() {
                switch (page) {
                  case 'Panel':
                    _currentPage = _NavPage.dashboard;
                    break;
                  case 'Alumnos':
                    _currentPage = _NavPage.alumnos;
                    break;
                  case 'Turnos':
                    _currentPage = _NavPage.turnos;
                    break;
                  case 'Pagos':
                    _currentPage = _NavPage.pagos;
                    break;
                }
              });
            },
          ),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}

// ─── Dashboard home content ───────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
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
                  'Buenos días, Studio.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto es lo que está pasando en Kali Studio hoy.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6),
                      size: 16),
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
                const SizedBox(height: 32),
                const DashboardBottomPromos(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Placeholder for future pages ─────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 56, color: KaliColors.espresso.withValues(alpha: 0.15)),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5),
                      size: 15),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: KaliColors.sand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Próximamente',
                    style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5)),
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
