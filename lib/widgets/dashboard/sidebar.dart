import 'package:flutter/material.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
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

  static const _blockedForAdmin = {'Entrenadores', 'Pagos'};

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
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Material(
        color: kaliColors.sand,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/argity_logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'argity',
                      style: KaliText.heading(kaliColors.espresso, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              _buildMenuItem(Icons.grid_view_rounded, 'Panel'),
              _buildMenuItem(Icons.people_outline, 'Alumnos'),
              if (_role != 'admin')
                _buildMenuItem(Icons.fitness_center_outlined, 'Entrenadores'),
              _buildMenuItem(Icons.calendar_today_outlined, 'Turnos'),
              if (_role != 'admin')
                _buildMenuItem(Icons.payment_outlined, 'Pagos'),
              const Spacer(),
              _buildBottomMenuItem(Icons.help_outline, 'SOPORTE', kaliColors),
            ],
          ),
        ));
  }

  Widget _buildMenuItem(IconData icon, String title) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final isActive = currentPage == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: isActive
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.transparent,
        leading: Icon(
          icon,
          color: isActive
              ? kaliColors.espresso
              : kaliColors.espresso.withValues(alpha: 0.6),
        ),
        title: Text(
          title,
          style: KaliText.body(
            isActive
                ? kaliColors.espresso
                : kaliColors.espresso.withValues(alpha: 0.6),
            weight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => widget.onNavigate(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBottomMenuItem(IconData icon, String title, KaliColorsExtension kaliColors) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse('https://argity.com');
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
                color: kaliColors.espresso.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: KaliText.label(kaliColors.espresso.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
