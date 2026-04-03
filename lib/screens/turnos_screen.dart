import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/data/mock_turnos.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/turnos/schedule_header.dart';
import 'package:kali_studio/widgets/turnos/weekly_schedule.dart';
import 'package:kali_studio/widgets/turnos/schedule_bottom_bar.dart';
import 'package:kali_studio/widgets/turnos/turno_detail_panel.dart';

/// Pantalla principal de Turnos (calendario semanal).
class TurnosScreen extends StatelessWidget {
  const TurnosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TurnosBloc, TurnosState>(
      builder: (context, state) {
        return Column(
          children: [
            const DashboardTopNavBar(),
            Expanded(
              child: Row(
                children: [
                  // ── Contenido principal ─────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ScheduleHeader(),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: WeeklySchedule(
                                      selectedTurno: state.selectedTurno,
                                      onTurnoSelected: (turno) {
                                        context.read<TurnosBloc>().add(
                                              TurnoSelected(turno),
                                            );
                                      },
                                    ),
                                  ),
                                  const ScheduleBottomBar(
                                    turnos: kMockTurnos,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Panel lateral de detalles ───────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: state.hasSelection
                        ? Padding(
                            padding:
                                const EdgeInsets.fromLTRB(0, 16, 24, 24),
                            child: TurnoDetailPanel(
                              turno: state.selectedTurno!,
                              onClose: () {
                                context
                                    .read<TurnosBloc>()
                                    .add(TurnoDeselected());
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
