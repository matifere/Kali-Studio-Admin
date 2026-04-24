import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Card del cronograma del día de hoy en el panel principal.
///
/// Consume [TurnosBloc] — si las sesiones de la semana actual ya están cargadas
/// las filtra localmente. Si no, dispara la carga en [initState].
class DashboardScheduleList extends StatefulWidget {
  const DashboardScheduleList({super.key});

  @override
  State<DashboardScheduleList> createState() => _DashboardScheduleListState();
}

class _DashboardScheduleListState extends State<DashboardScheduleList> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<TurnosBloc>();
    // Cargar la semana actual si aún no hay datos
    if (bloc.state.sessions.isEmpty) {
      bloc.add(TurnosLoadRequested(bloc.state.currentWeekStart));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TurnosBloc, TurnosState>(
      builder: (context, state) {
        // Filtrar solo las sesiones de hoy
        final today = DateTime.now();
        final todaySessions = state.sessions.where((s) {
          return s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day;
        }).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        // Determinar qué sesión está activa en este momento
        final nowMinutes = today.hour * 60 + today.minute;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: KaliColors.sand,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cronograma de Hoy',
                    style: KaliText.headingItalic(KaliColors.espresso, size: 28)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    DateFormat('EEEE d MMM', 'es_ES').format(today),
                    style: KaliText.label(KaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Contenido ─────────────────────────────────────────────────
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: LinearProgressIndicator()),
                )
              else if (state.error != null)
                _ErrorMessage(state.error!)
              else if (todaySessions.isEmpty)
                const _EmptyToday()
              else
                ...todaySessions.map((session) {
                  final start = _toMinutes(session.startTime);
                  final end = _toMinutes(session.endTime);
                  final isActive = nowMinutes >= start && nowMinutes < end;
                  final isPast = nowMinutes >= end;

                  return _SessionItem(
                    session: session,
                    isActive: isActive,
                    isPast: isPast,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  int _toMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

// ── Item de sesión ─────────────────────────────────────────────────────────────
class _SessionItem extends StatelessWidget {
  final ClassSession session;
  final bool isActive;
  final bool isPast;

  const _SessionItem({
    required this.session,
    required this.isActive,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final timeParts = session.startTime.split(':');
    final hour = int.parse(timeParts[0]);
    final timeStr = '${hour.toString().padLeft(2, '0')}:${timeParts[1]}';
    final period = hour < 12 ? 'AM' : 'PM';

    final isFull = session.isFull;
    final occupancyColor = isFull
        ? const Color(0xFFD4685C)
        : isActive
            ? const Color(0xFF5C9E6C)
            : KaliColors.clayDark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isPast ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isActive ? KaliColors.espresso : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            // ── Hora ───────────────────────────────────────────────────────
            SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeStr,
                    style: KaliText.heading(
                      isActive ? KaliColors.warmWhite : KaliColors.espresso,
                      size: 18,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    period,
                    style: KaliText.label(
                      isActive
                          ? KaliColors.warmWhite.withValues(alpha: 0.7)
                          : KaliColors.clayDark,
                    ),
                  ),
                ],
              ),
            ),

            // ── Barra activa ────────────────────────────────────────────────
            if (isActive)
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: KaliColors.clay,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              )
            else
              const SizedBox(width: 28),

            // ── Info de la clase ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: KaliText.body(
                      isActive ? KaliColors.warmWhite : KaliColors.espresso,
                      weight: FontWeight.w700,
                      size: 14,
                    ),
                  ),
                  if (session.instructorName != null &&
                      session.instructorName!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Instructor: ${session.instructorName}',
                      style: KaliText.body(
                        isActive
                            ? KaliColors.warmWhite.withValues(alpha: 0.75)
                            : KaliColors.clayDark,
                        size: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Ocupación ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      session.occupancyText,
                      style: KaliText.body(
                        isActive ? KaliColors.warmWhite : KaliColors.espresso,
                        weight: FontWeight.w700,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? KaliColors.clay : occupancyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isFull
                      ? 'SALA LLENA'
                      : '${((session.enrolled / session.capacity) * 100).round()}% OCUPACIÓN',
                  style: KaliText.label(
                    isActive
                        ? KaliColors.warmWhite.withValues(alpha: 0.75)
                        : KaliColors.espresso,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────
class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 36,
              color: KaliColors.espresso.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay clases programadas para hoy',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────
class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: KaliText.body(const Color(0xFFD4685C)),
      ),
    );
  }
}
