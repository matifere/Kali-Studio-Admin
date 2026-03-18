import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'booking_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedDay = 2; // Miércoles seleccionado
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHero()),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SectionLabel('Tu próxima clase'),
                _buildNextClassCard(),
                const SizedBox(height: 20),
                const SectionLabel('Semana actual'),
                WeekStrip(
                  selectedIndex: _selectedDay,
                  onDaySelected: (i) => setState(() => _selectedDay = i),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Hoy · Miércoles 18'),
                ...KaliData.todayClasses.map((cls) => Column(
                  children: [
                    ClassListItem(
                      cls: cls,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(pilatesClass: cls),
                        ),
                      ),
                    ),
                    if (cls != KaliData.todayClasses.last)
                      Divider(color: KaliColors.sand2, height: 1),
                  ],
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: KaliColors.espresso,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60, right: -60,
            child: _decorCircle(220, 0.18),
          ),
          Positioned(
            top: 10, right: -20,
            child: _decorCircle(140, 0.12),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenida de vuelta',
                style: KaliText.label(KaliColors.clay)
                    .copyWith(letterSpacing: 1.8)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: 'Hola, ',
                  style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 28),
                  children: [
                    TextSpan(
                      text: 'Valentina',
                      style: GoogleFontsHelper.cormorant(
                        KaliColors.clay, 28, italic: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Streak pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: KaliColors.clay.withOpacity(0.15),
                  border: Border.all(color: KaliColors.clay.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: KaliColors.clay,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('12 clases este mes',
                      style: KaliText.caption(KaliColors.clay)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: KaliColors.clay.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildNextClassCard() {
    final next = KaliData.todayClasses.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KaliColors.clay.withOpacity(0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: next.time,
                  style: GoogleFontsHelper.cormorant(KaliColors.warmWhite, 36),
                  children: [
                    TextSpan(
                      text: '  ${next.period}',
                      style: KaliText.body(KaliColors.clay, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('${next.name} · Hoy, Miércoles',
                style: KaliText.caption(KaliColors.clay)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _tag(next.instructor.split(' ').first),
                  const SizedBox(width: 8),
                  _tag('${next.durationMin} min'),
                  const SizedBox(width: 8),
                  _tag(next.room),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(pilatesClass: next),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: KaliColors.clay,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Ver clase',
                        style: KaliText.body(KaliColors.espresso,
                            size: 11, weight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
        style: KaliText.caption(Colors.white.withOpacity(0.7))
            .copyWith(fontSize: 10)),
    );
  }
}
