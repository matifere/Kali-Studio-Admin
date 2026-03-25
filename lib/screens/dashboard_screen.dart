import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/dashboard/sidebar.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/dashboard/stat_cards.dart';
import 'package:kali_studio/widgets/dashboard/schedule_list.dart';
import 'package:kali_studio/widgets/dashboard/recent_activity.dart';
import 'package:kali_studio/widgets/dashboard/bottom_promos.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      floatingActionButton: FloatingActionButton(
        foregroundColor: KaliColors.warmWhite,
        backgroundColor: KaliColors.espresso,
        onPressed: () {},
        child: const Icon(Icons.add, color: KaliColors.warmWhite),
      ),
      body: Row(
        children: [
          // Sidebar
          const DashboardSidebar(),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Navigation Bar
                const DashboardTopNavBar(),
                
                // Content
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
                          style: KaliText.body(KaliColors.espresso.withOpacity(0.6), size: 16),
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
            ),
          )
        ],
      ),
    );
  }
}
