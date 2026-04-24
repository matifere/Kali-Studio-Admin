import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/activity/activity_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardRecentActivity extends StatelessWidget {
  const DashboardRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: KaliColors.sand,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Actividad Reciente',
                    style: KaliText.headingItalic(KaliColors.espresso, size: 28)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (state.entries.isNotEmpty)
                    _ClearButton(
                      onTap: () => context.read<ActivityBloc>().add(ActivityCleared()),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Contenido ─────────────────────────────────────────────────
              if (state.entries.isEmpty)
                _EmptyFeed()
              else
                ...state.entries.asMap().entries.map((entry) {
                  final isLast = entry.key == state.entries.length - 1;
                  return _ActivityItem(
                    activityEntry: entry.value,
                    isLast: isLast,
                  );
                }),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Botón para limpiar el feed ─────────────────────────────────────────────────
class _ClearButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 1.0 : 0.5,
          child: Text(
            'LIMPIAR',
            style: KaliText.label(KaliColors.espresso),
          ),
        ),
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 36,
              color: KaliColors.espresso.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay actividad registrada.',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 4),
            Text(
              'Los cambios que hagas aparecerán aquí.',
              style: KaliText.caption(KaliColors.espresso.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item de actividad ──────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final ActivityEntry activityEntry;
  final bool isLast;

  const _ActivityItem({required this.activityEntry, required this.isLast});

  /// Icono y color por categoría.
  (IconData, Color) get _iconAndColor => switch (activityEntry.category) {
        ActivityCategory.alumno => (Icons.person_add_rounded, KaliColors.sage),
        ActivityCategory.turno  => (Icons.event_rounded,      KaliColors.clayDark),
        ActivityCategory.pago   => (Icons.payment_rounded,    const Color(0xFF5C9E6C)),
        ActivityCategory.perfil => (Icons.manage_accounts_rounded, KaliColors.clay),
      };

  String _formatTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'AHORA';
    if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes} MIN';
    if (diff.inHours < 24) return 'HACE ${diff.inHours} H';
    return 'HACE ${diff.inDays} DÍA${diff.inDays > 1 ? 'S' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline indicator ────────────────────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: KaliColors.espresso.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Texto ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(activityEntry.timestamp),
                    style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.45)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityEntry.title,
                    style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activityEntry.subtitle,
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
