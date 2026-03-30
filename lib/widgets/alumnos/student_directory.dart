import 'package:flutter/material.dart';
import 'package:kali_studio/data/mock_students.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/alumnos/student_row.dart';
import 'package:kali_studio/widgets/common/kali_empty_state.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/common/kali_pagination.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // 1. Declaramos el Future como variable de estado
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    // Lo inicializamos una sola vez cuando el widget nace
    _studentsFuture = getStudentsFromDB();
  }

  Future<List<Student>> getStudentsFromDB() async {
    // Le decimos explícitamente a Supabase qué relación (foreign key) usar
    // usando la sintaxis tabla!nombre_de_la_foreign_key
    final response = await Supabase.instance.client.from('profiles').select('''
      *, 
      subscriptions!subscriptions_user_id_fkey(*, plans(*)), 
      reservations!reservations_user_id_fkey(*, class_sessions(*))
    ''');

    return response.map((data) => Student.fromJson(data)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
      child: FutureBuilder<List<Student>>(
        future:
            _studentsFuture, // Pasamos la variable, no la función directamente
        builder: (context, snapshot) {
          // 2. Manejamos el estado de espera
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Manejamos posibles errores
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Obtenemos los datos seguros
          final allStudents = snapshot.data ?? [];

          // 3. Calculamos la paginación basados en los datos reales
          final totalStudents = allStudents.length;
          final totalPages = (totalStudents / _perPage).ceil().clamp(1, 999);

          final start = (_currentPage - 1) * _perPage;
          final end = (start + _perPage).clamp(0, totalStudents);
          final pageStudents = allStudents.isEmpty
              ? <Student>[]
              : allStudents.sublist(start, end);

          // Construimos la UI
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (allStudents.isEmpty)
                const KaliEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Aún no hay alumnos registrados',
                  subtitle:
                      'Añadí tu primer alumno para comenzar a gestionar tu comunidad.',
                )
              else ...[
                _buildColumnHeaders(),
                ...pageStudents.map((s) => StudentRow(student: s)),
                KaliPagination(
                  currentPage: _currentPage,
                  totalPages: totalPages,
                  showingCount: pageStudents.length,
                  totalCount: totalStudents,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                ),
              ],
            ],
          );
        },
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
    final style = KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));

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
