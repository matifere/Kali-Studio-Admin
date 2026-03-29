import 'package:flutter/material.dart';
import 'package:kali_studio/data/mock_turnos.dart';
import 'package:kali_studio/models/turno.dart';
import 'package:kali_studio/widgets/dashboard/top_navbar.dart';
import 'package:kali_studio/widgets/turnos/schedule_header.dart';
import 'package:kali_studio/widgets/turnos/weekly_schedule.dart';
import 'package:kali_studio/widgets/turnos/schedule_bottom_bar.dart';
import 'package:kali_studio/widgets/turnos/turno_detail_panel.dart';

/// Pantalla principal de Turnos (calendario semanal).
class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  Turno? _selectedTurno;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: Row(
            children: [
              // Contenido principal
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
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: WeeklySchedule(
                                  selectedTurno: _selectedTurno,
                                  onTurnoSelected: (turno) {
                                    setState(() {
                                      _selectedTurno =
                                          _selectedTurno == turno
                                              ? null
                                              : turno;
                                    });
                                  },
                                ),
                              ),
                              const ScheduleBottomBar(turnos: kMockTurnos),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Panel lateral de detalles
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _selectedTurno != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                        child: TurnoDetailPanel(
                          turno: _selectedTurno!,
                          onClose: () =>
                              setState(() => _selectedTurno = null),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
