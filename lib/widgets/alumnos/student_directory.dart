import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_row.dart';
import 'package:kali_studio/widgets/common/kali_empty_state.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/common/kali_pagination.dart';

/// Directorio paginado de alumnos.
///
/// Consume [AlumnosBloc] para los datos y la paginación.
/// No tiene estado propio — es un [StatelessWidget] puro.
class StudentDirectory extends StatelessWidget {
  const StudentDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlumnosBloc, AlumnosState>(
      builder: (context, state) {
        return Container(
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
          child: switch (state) {
            // ── Cargando ───────────────────────────────────────────────────
            AlumnosLoading() => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: LinearProgressIndicator()),
              ),

            // ── Error ──────────────────────────────────────────────────────
            AlumnosError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    'Error: $message',
                    style: KaliText.body(KaliColors.espresso),
                  ),
                ),
              ),

            // ── Datos listos ───────────────────────────────────────────────
            AlumnosLoaded() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  if (state.students.isEmpty)
                    const KaliEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'Aún no hay alumnos registrados',
                      subtitle:
                          'Añadí tu primer alumno para comenzar a gestionar tu comunidad.',
                    )
                  else ...[
                    _buildColumnHeaders(),
                    ...state.pageStudents.map((s) => StudentRow(student: s)),
                    KaliPagination(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      showingCount: state.pageStudents.length,
                      totalCount: state.students.length,
                      onPageChanged: (page) {
                        context
                            .read<AlumnosBloc>()
                            .add(AlumnosPageChanged(page));
                      },
                    ),
                  ],
                ],
              ),

            // ── Estado inicial (no debería verse) ─────────────────────────
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Directorio de Alumnos',
            style: KaliText.headingItalic(KaliColors.espresso, size: 22),
          ),
          const Row(
            children: [
              KaliIconButton(Icons.tune_rounded, tooltip: 'Filtrar'),
              SizedBox(width: 8),
              KaliIconButton(Icons.download_rounded, tooltip: 'Exportar'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Encabezados de columna ─────────────────────────────────────────────────
  Widget _buildColumnHeaders() {
    final style =
        KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('NOMBRE', style: style)),
          Expanded(flex: 3, child: Text('PLAN', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 3, child: Text('PRÓXIMO TURNO', style: style)),
          Expanded(flex: 2, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}
