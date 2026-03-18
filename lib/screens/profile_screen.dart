import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildStats()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SectionLabel('Mi cuenta'),
              _menuItem(Icons.receipt_long_outlined,
                  'Historial de clases', '47 clases completadas'),
              _divider(),
              _menuItem(Icons.calendar_today_outlined,
                  'Mis reservas', '3 próximas clases'),
              _divider(),
              _menuItem(Icons.credit_card_outlined,
                  'Mi plan', 'Mensual · Vence 31 mar'),
              _divider(),
              _menuItem(Icons.notifications_outlined,
                  'Notificaciones', 'Recordatorios activados'),
              _divider(),
              _menuItem(Icons.settings_outlined,
                  'Configuración', 'Privacidad, cuenta'),
              const SizedBox(height: 24),
              const SectionLabel('Sesión'),
              _menuItem(Icons.logout, 'Cerrar sesión', '',
                  color: KaliColors.clay),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: KaliColors.espresso,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: KaliColors.clayDark,
              shape: BoxShape.circle,
              border: Border.all(color: KaliColors.clay, width: 2),
            ),
            child: Center(
              child: Text('V',
                style: GoogleFontsHelper.cormorant(
                    KaliColors.warmWhite, 30, italic: true)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Valentina Moreno',
            style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 22)),
          const SizedBox(height: 4),
          Text('Plan Mensual · 8 clases',
            style: KaliText.label(KaliColors.clay)
                .copyWith(letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      color: KaliColors.sand,
      child: Row(
        children: [
          _statCell('12', 'Este mes'),
          Container(width: 1, height: 50, color: KaliColors.sand2),
          _statCell('47', 'Total'),
          Container(width: 1, height: 50, color: KaliColors.sand2),
          _statCell('6', 'Restantes'),
        ],
      ),
    );
  }

  Widget _statCell(String num, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(num,
              style: GoogleFontsHelper.cormorant(KaliColors.espresso, 26)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
              style: KaliText.label(KaliColors.clayDark)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18,
                color: color ?? KaliColors.clay),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: KaliText.body(color ?? KaliColors.espresso,
                      size: 13, weight: FontWeight.w400)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(subtitle,
                    style: KaliText.caption(KaliColors.clayDark)),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 12, color: KaliColors.clay),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: KaliColors.sand2, height: 1);
}
