import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardSidebar extends StatelessWidget {
  final String currentPage;
  final void Function(String page) onNavigate;

  const DashboardSidebar({
    super.key,
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: KaliColors.sand,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 48),
          _buildMenuItem(Icons.grid_view_rounded, 'Panel'),
          _buildMenuItem(Icons.people_outline, 'Alumnos'),
          _buildMenuItem(Icons.calendar_today_outlined, 'Turnos'),
          _buildMenuItem(Icons.payment_outlined, 'Pagos'),
          const Spacer(),
          _buildBottomMenuItem(Icons.help_outline, 'SOPORTE'),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kali Studio',
            style: KaliText.display(KaliColors.espresso).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'PORTAL DE GESTIÓN',
            style: KaliText.label(KaliColors.clayDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    final isActive = currentPage == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? KaliColors.espresso
              : KaliColors.espresso.withValues(alpha: 0.6),
        ),
        title: Text(
          title,
          style: KaliText.body(
            isActive
                ? KaliColors.espresso
                : KaliColors.espresso.withValues(alpha: 0.6),
            weight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => onNavigate(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }



  Widget _buildBottomMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon,
                color: KaliColors.espresso.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
