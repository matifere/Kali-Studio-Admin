import 'package:flutter/material.dart';
import 'package:kali_studio/data/mock_students.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_row.dart';
import 'package:kali_studio/widgets/common/kali_empty_state.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/common/kali_pagination.dart';

/// Directorio paginado de alumnos.
///
/// Recibe una lista de [Student] y se encarga de la paginación,
/// los headers de columna y el estado vacío.
class StudentDirectory extends StatefulWidget {
  final List<Student> students;

  const StudentDirectory({
    super.key,
    this.students = kMockStudents,
  });

  @override
  State<StudentDirectory> createState() => _StudentDirectoryState();
}

class _StudentDirectoryState extends State<StudentDirectory> {
  int _currentPage = 1;
  static const int _perPage = 4;

  // ── Paginación ─────────────────────────────────────────────────────────────
  int get _totalStudents => widget.students.length;
  int get _totalPages => (_totalStudents / _perPage).ceil().clamp(1, 999);

  List<Student> get _pageStudents {
    if (widget.students.isEmpty) return [];
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _totalStudents);
    return widget.students.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final students = _pageStudents;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (widget.students.isEmpty)
            const KaliEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Aún no hay alumnos registrados',
              subtitle:
                  'Añadí tu primer alumno para comenzar a gestionar tu comunidad.',
            )
          else ...[
            _buildColumnHeaders(),
            ...students.map((s) => StudentRow(student: s)),
            KaliPagination(
              currentPage: _currentPage,
              totalPages: _totalPages,
              showingCount: students.length,
              totalCount: _totalStudents,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          ],
        ],
      ),
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
