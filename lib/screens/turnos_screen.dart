import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/turnos/schedule_header.dart';
import 'package:kali_studio/widgets/turnos/weekly_schedule.dart';
import 'package:kali_studio/widgets/turnos/schedule_bottom_bar.dart';
import 'package:kali_studio/widgets/turnos/turno_detail_panel.dart';
import 'package:kali_studio/widgets/turnos/create_turno_dialog.dart';
import 'package:kali_studio/widgets/turnos/create_template_dialog.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Pantalla principal de Turnos (calendario semanal).
class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<TurnosBloc>();
    if (bloc.state.sessions.isEmpty && !bloc.state.isLoading) {
      bloc.add(TurnosLoadRequested(bloc.state.currentWeekStart));
    } else if (bloc.state.isLoading == true && bloc.state.sessions.isEmpty) {
       bloc.add(TurnosLoadRequested(bloc.state.currentWeekStart));
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TurnosBloc>(),
        child: const CreateTurnoDialog(),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (_) => const CreateTemplateDialog(),
    );
  }

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
                          ScheduleHeader(
                            currentWeekStart: state.currentWeekStart,
                            onPreviousWeek: () {
                              final prev = state.currentWeekStart.subtract(const Duration(days: 7));
                              context.read<TurnosBloc>().add(TurnosWeekChanged(prev));
                            },
                            onNextWeek: () {
                              final next = state.currentWeekStart.add(const Duration(days: 7));
                              context.read<TurnosBloc>().add(TurnosWeekChanged(next));
                            },
                            onCreateTurno: _showCreateDialog,
                            onCreateTemplate: _showCreateTemplateDialog,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: state.isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : state.error != null
                                      ? Center(
                                          child: Text(
                                            state.error!,
                                            style: KaliText.body(KaliColors.espresso),
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            Expanded(
                                              child: WeeklySchedule(
                                                currentWeekStart: state.currentWeekStart,
                                                sessions: state.sessions,
                                                selectedTurno: state.selectedTurno,
                                                onTurnoSelected: (turno) {
                                                  context.read<TurnosBloc>().add(
                                                        TurnoSelected(turno),
                                                      );
                                                },
                                              ),
                                            ),
                                            const ScheduleBottomBar(
                                              turnos: [], // Deprecated for now, mock data removed
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
                            padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                            child: TurnoDetailPanel(
                              turno: state.selectedTurno!, // Note: detail panel will need to be updated to support ClassSession instead of Turno
                              onClose: () {
                                context.read<TurnosBloc>().add(TurnoDeselected());
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
