import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/kali_theme.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    _ScheduleScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _NavItem(icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month, label: 'Reservar'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: KaliColors.warmWhite,
        border: Border(top: BorderSide(color: KaliColors.sand2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final isActive = i == _currentIndex;
              final item = _navItems[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive
                              ? KaliColors.espresso
                              : KaliColors.clayDark,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label.toUpperCase(),
                          style: KaliText.label(
                            isActive
                                ? KaliColors.espresso
                                : KaliColors.clayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ─── Pantalla de búsqueda/agenda ───────────────────────────────────────────────
class _ScheduleScreen extends StatelessWidget {
  const _ScheduleScreen();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: KaliColors.espresso,
          expandedHeight: 100,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Reservar clase',
              style: GoogleFontsHelper.cormorant(
                  KaliColors.warmWhite, 20, italic: true)),
            centerTitle: true,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: KaliColors.sand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: KaliColors.clay, size: 18),
                    const SizedBox(width: 10),
                    Text('Buscar clase o instructor…',
                      style: KaliText.caption(KaliColors.clayDark)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Reformer', 'Mat', 'Restaurativo', 'Avanzado']
                      .asMap().entries.map((e) {
                    final isFirst = e.key == 0;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFirst ? KaliColors.espresso : KaliColors.sand2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(e.value,
                        style: KaliText.body(
                          isFirst ? KaliColors.clay : KaliColors.clayDark,
                          size: 12)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const SectionLabel('Esta semana'),
              const SizedBox(height: 8),

              // Class cards
              ...List.generate(5, (i) => _ClassCard(index: i)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final int index;
  const _ClassCard({required this.index});

  static const _data = [
    ('Reformer Avanzado', 'Luciana Paz', 'Mié 18 · 6:30 PM', '2 lugares'),
    ('Mat Flow', 'Sofía Ríos', 'Jue 19 · 10:00 AM', '8 lugares'),
    ('Pilates Restaurativo', 'Camila Ortiz', 'Jue 19 · 12:00 PM', '5 lugares'),
    ('Reformer Principiantes', 'Sofía Ríos', 'Vie 20 · 9:00 AM', '6 lugares'),
    ('Reformer Intermedio', 'Luciana Paz', 'Sáb 21 · 8:00 AM', '4 lugares'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = _data[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.$1,
                  style: KaliText.body(KaliColors.espresso,
                      size: 14, weight: FontWeight.w400)),
                const SizedBox(height: 2),
                Text('${d.$2} · ${d.$3}',
                  style: KaliText.caption(KaliColors.clayDark)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KaliColors.espresso,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Reservar',
                  style: KaliText.body(KaliColors.clay,
                      size: 11, weight: FontWeight.w500)),
              ),
              const SizedBox(height: 4),
              Text(d.$4,
                style: KaliText.caption(KaliColors.sage)
                    .copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
