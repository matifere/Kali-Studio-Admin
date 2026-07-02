import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/bloc/navigation/navigation_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/dashboard/sidebar.dart';
import 'package:argrity/widgets/dashboard/stat_cards.dart';
import 'package:argrity/widgets/dashboard/schedule_list.dart';
import 'package:argrity/screens/alumnos_screen.dart';
import 'package:argrity/screens/entrenadores_screen.dart';
import 'package:argrity/screens/turnos_screen.dart';
import 'package:argrity/screens/pagos_screen.dart';
import 'package:argrity/screens/settings/settings_theme_screen.dart';
import 'package:argrity/bloc/dashboard/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _buildCurrentPage(String page) {
    switch (page) {
      case 'Alumnos':
        return const AlumnosScreen();
      case 'Entrenadores':
        return const EntrenadoresScreen();
      case 'Turnos':
        return const TurnosScreen();
      case 'Pagos':
        return const PagosScreen();
      case 'Tema':
        return const SettingsThemeScreen();
      default:
        return const _DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          backgroundColor: kaliColors.warmWhite,
          drawer: isMobile
              ? Drawer(
                  child: DashboardSidebar(
                    currentPage: navState.currentPage,
                    onNavigate: (page) {
                      context.read<NavigationBloc>().add(
                            NavigationPageChanged(page),
                          );
                      Navigator.of(context).pop(); // Cerrar drawer al navegar
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile)
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
    final bloc = context.read<DashboardBloc>();
    if (!bloc.state.isLoading) {
      bloc.add(DashboardLoadRequested());
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isSmall ? 32 : 40,
                    fontWeight: FontWeight.w600,
                    color: kaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto es lo que está pasando hoy.',
                  style: KaliText.body(
                    kaliColors.espresso.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
                const SizedBox(height: 40),
                const DashboardStatCards(),
                const SizedBox(height: 32),
                const DashboardScheduleList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
