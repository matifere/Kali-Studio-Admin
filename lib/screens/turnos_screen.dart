import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/widgets/dashboard/top_navbar.dart';
import 'package:argrity/widgets/turnos/schedule_header.dart';
import 'package:argrity/widgets/turnos/weekly_schedule.dart';
import 'package:argrity/widgets/turnos/schedule_bottom_bar.dart';
import 'package:argrity/widgets/turnos/turno_detail_panel.dart';
import 'package:argrity/widgets/turnos/create_class_group_dialog.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/services/profile_cache.dart';

/// Pantalla principal de Turnos (calendario semanal).
class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  final bool _isProfesor = ProfileCache.isAdmin;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TurnosBloc>();
    bloc.add(TurnosLoadRequested(bloc.state.currentWeekStart));
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TurnosBloc>(),
        child: const CreateClassGroupDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TurnosBloc, TurnosState>(
      listenWhen: (prev, curr) {
        final isMobile = MediaQuery.of(context).size.width < 700;
        return isMobile && !prev.hasSelection && curr.hasSelection;
      },
      listener: (ctx, state) {
        if (!state.hasSelection) return;
        showModalBottomSheet(
          context: ctx,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetCtx) => BlocProvider.value(
            value: ctx.read<TurnosBloc>(),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: TurnoDetailPanel(
                turno: state.selectedTurno!,
                onClose: () {
                  ctx.read<TurnosBloc>().add(TurnoDeselected());
                  Navigator.of(sheetCtx).pop();
                },
              ),
            ),
          ),
        ).then((_) {
          if (ctx.mounted) ctx.read<TurnosBloc>().add(TurnoDeselected());
        });
      },
      builder: (context, state) {
        final isMobile = MediaQuery.of(context).size.width < 700;
        return Column(
          children: [
            const DashboardTopNavBar(),
            Expanded(
              child: Row(
                children: [
                  // ── Contenido principal ─────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 40, 16, isMobile ? 16 : 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScheduleHeader(
                            currentWeekStart: state.currentWeekStart,
                            selectedInstructor: state.selectedInstructor,
                            selectedRoom: state.selectedRoom,
                            availableInstructors: state.availableInstructors,
                            availableRooms: state.availableRooms,
                            showInstructorFilter: !_isProfesor,
                            showDropdownFilters: !_isProfesor,
                            onFilterChanged: (instructor, room) {
                              context.read<TurnosBloc>().add(
                                    TurnosFilterChanged(
                                      instructor: instructor,
                                      room: room,
                                    ),
                                  );
                            },
                            onPreviousWeek: () {
                              final prev = state.currentWeekStart.subtract(const Duration(days: 7));
                              context.read<TurnosBloc>().add(TurnosWeekChanged(prev));
                            },
                            onNextWeek: () {
                              final next = state.currentWeekStart.add(const Duration(days: 7));
                              context.read<TurnosBloc>().add(TurnosWeekChanged(next));
                            },
                            onCreateTurno: _isProfesor ? null : _showCreateDialog,
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
                                                  sessions: state.filteredSessions,
                                                  selectedTurno: state.selectedTurno,
                                                  onTurnoSelected: (turno) {
                                                  context.read<TurnosBloc>().add(
                                                        TurnoSelected(turno),
                                                      );
                                                },
                                              ),
                                            ),
                                            ScheduleBottomBar(
                                              sessions: state.filteredSessions,
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Panel lateral de detalles (solo desktop) ────────────
                  if (!isMobile)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: state.hasSelection
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                              child: TurnoDetailPanel(
                                turno: state.selectedTurno!,
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
