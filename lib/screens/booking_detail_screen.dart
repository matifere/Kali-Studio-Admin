import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class BookingDetailScreen extends StatefulWidget {
  final PilatesClass pilatesClass;

  const BookingDetailScreen({super.key, required this.pilatesClass});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Detalles', 'Instructor', 'Ubicación'];

  @override
  Widget build(BuildContext context) {
    final cls = widget.pilatesClass;

    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: Column(
        children: [
          _buildHeader(cls),
          _buildTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildDetailsTab(cls),
                _buildInstructorTab(),
                _buildLocationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PilatesClass cls) {
    return Container(
      color: KaliColors.warmWhite,
      padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios,
                    size: 12, color: KaliColors.clayDark),
                const SizedBox(width: 4),
                Text('Volver',
                  style: KaliText.body(KaliColors.clayDark, size: 12)
                      .copyWith(letterSpacing: 0.6)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(cls.name,
            style: GoogleFontsHelper.cormorant(
                KaliColors.espresso, 26, italic: true)),
          const SizedBox(height: 4),
          Text('Hoy, Miércoles 18 · ${cls.time} ${cls.period}',
            style: KaliText.caption(KaliColors.clayDark)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KaliColors.sand2)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? KaliColors.clay
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: KaliText.body(
                    isActive ? KaliColors.espresso : KaliColors.clayDark,
                    size: 11,
                    weight: isActive ? FontWeight.w500 : FontWeight.w300,
                  ).copyWith(letterSpacing: 0.8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailsTab(PilatesClass cls) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructor card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    color: KaliColors.clay,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      KaliData.luciana.initials,
                      style: GoogleFontsHelper.cormorant(
                          KaliColors.warmWhite, 18, italic: true),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(KaliData.luciana.name,
                      style: KaliText.body(KaliColors.espresso,
                          size: 14, weight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text('${KaliData.luciana.certification} · '
                        '${KaliData.luciana.yearsExp} años',
                      style: KaliText.caption(KaliColors.clayDark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Detail grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              DetailBox(label: 'Duración', value: '${cls.durationMin} min'),
              DetailBox(label: 'Nivel', value: cls.level),
              DetailBox(label: 'Sala', value: cls.room),
              DetailBox(label: 'Equipamiento', value: cls.equipment),
            ],
          ),
          const SizedBox(height: 18),

          // Spots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponibles: ${cls.availableSpots} de ${cls.totalSpots}',
                style: KaliText.caption(KaliColors.clayDark),
              ),
              Row(
                children: List.generate(cls.totalSpots, (i) => Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < cls.takenSpots
                        ? KaliColors.clay
                        : KaliColors.sageLight,
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Description
          Text(
            cls.description,
            style: KaliText.body(KaliColors.clayDark, size: 13,
                weight: FontWeight.w300)
                .copyWith(fontStyle: FontStyle.italic, height: 1.7),
          ),
          const SizedBox(height: 24),

          // Book button
          if (!cls.isBooked)
            KaliButton(text: 'Confirmar reserva', onPressed: _onBook)
          else
            KaliButton(text: 'Cancelar reserva', onPressed: _onCancel,
                outlined: true),
        ],
      ),
    );
  }

  Widget _buildInstructorTab() {
    final inst = KaliData.luciana;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: KaliColors.clay,
                    shape: BoxShape.circle,
                    border: Border.all(color: KaliColors.sand2, width: 3),
                  ),
                  child: Center(
                    child: Text(inst.initials,
                      style: GoogleFontsHelper.cormorant(
                          KaliColors.warmWhite, 28, italic: true)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(inst.name,
                  style: GoogleFontsHelper.cormorant(KaliColors.espresso, 22)),
                const SizedBox(height: 4),
                Text(inst.certification,
                  style: KaliText.caption(KaliColors.clayDark)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: KaliColors.sand2),
          const SizedBox(height: 16),
          const SectionLabel('Sobre ella'),
          Text(inst.bio,
            style: KaliText.body(KaliColors.clayDark, size: 13,
                weight: FontWeight.w300)
                .copyWith(height: 1.8)),
          const SizedBox(height: 20),
          _statRow('Años de experiencia', '${inst.yearsExp}'),
          _statRow('Clases por semana', '12'),
          _statRow('Especialidad', 'Reformer & Clínico'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: KaliText.caption(KaliColors.clayDark)),
          Text(value,
            style: GoogleFontsHelper.cormorant(KaliColors.espresso, 18)),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                    color: KaliColors.clay, size: 32),
                  const SizedBox(height: 8),
                  Text('Kali Studio · Palermo',
                    style: GoogleFontsHelper.cormorant(
                        KaliColors.espresso, 18, italic: true)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _locationRow(Icons.location_on_outlined, 'El Salvador 4832, Palermo'),
          _locationRow(Icons.directions_subway_outlined, '5 min de Scalabrini Ortiz'),
          _locationRow(Icons.local_parking_outlined, 'Estacionamiento disponible'),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KaliColors.clay),
          const SizedBox(width: 12),
          Text(text, style: KaliText.body(KaliColors.espresso, size: 13)),
        ],
      ),
    );
  }

  void _onBook() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KaliColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmationSheet(cls: widget.pilatesClass),
    );
  }

  void _onCancel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserva cancelada',
          style: KaliText.body(KaliColors.clay)),
        backgroundColor: KaliColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Bottom sheet de confirmación ─────────────────────────────────────────────
class _ConfirmationSheet extends StatelessWidget {
  final PilatesClass cls;
  const _ConfirmationSheet({required this.cls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: KaliColors.sand2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: KaliColors.espresso,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: KaliColors.clay, size: 24),
          ),
          const SizedBox(height: 16),
          Text('¡Reserva confirmada!',
            style: GoogleFontsHelper.cormorant(KaliColors.espresso, 24)),
          const SizedBox(height: 8),
          Text('${cls.name} · ${cls.time} ${cls.period}',
            style: KaliText.caption(KaliColors.clayDark),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          KaliButton(
            text: 'Ver mis reservas',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          KaliButton(
            text: 'Volver al inicio',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            outlined: true,
          ),
        ],
      ),
    );
  }
}
