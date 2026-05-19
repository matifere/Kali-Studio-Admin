import 'package:flutter/material.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardSidebar extends StatefulWidget {
  final String currentPage;
  final void Function(String page) onNavigate;

  const DashboardSidebar({
    super.key,
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  // El rol está en el JWT local — sin round trip a la base de datos.
  late final String _role = ProfileCache.role;

  static const _blockedForAdmin = {'Panel', 'Entrenadores', 'Pagos'};

  @override
  void initState() {
    super.initState();
    if (_role == 'admin' && _blockedForAdmin.contains(widget.currentPage)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNavigate('Alumnos');
      });
    }
  }

  String get currentPage => widget.currentPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: KaliColors.sand,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHIMPANCE ADMIN',
                  style: KaliText.label(KaliColors.clayDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          if (_role != 'admin') _buildMenuItem(Icons.grid_view_rounded, 'Panel'),
          _buildMenuItem(Icons.people_outline, 'Alumnos'),
          if (_role != 'admin')
            _buildMenuItem(Icons.fitness_center_outlined, 'Entrenadores'),
          _buildMenuItem(Icons.calendar_today_outlined, 'Turnos'),
          if (_role != 'admin') _buildMenuItem(Icons.payment_outlined, 'Pagos'),
          const Spacer(),
          _buildBottomMenuItem(Icons.help_outline, 'SOPORTE'),
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
        onTap: () => widget.onNavigate(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBottomMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse('https://middleouttech.netlify.app/');
        try {
          await launchUrl(url);
        } catch (e) {
          debugPrint('No se pudo abrir el enlace: $e');
        }
      },
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
