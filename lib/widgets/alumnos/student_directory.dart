import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:argrity/bloc/alumnos/alumnos_bloc.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/alumnos/student_row.dart';
import 'package:argrity/widgets/common/kali_empty_state.dart';
import 'package:argrity/widgets/common/kali_icon_button.dart';
import 'package:argrity/widgets/common/kali_pagination.dart';
import 'package:argrity/widgets/alumnos/alumnos_filter_dialog.dart';

/// Directorio paginado de alumnos.
///
/// Consume [AlumnosBloc] para los datos y la paginación.
/// Usa un [TextEditingController] para mantener el texto de búsqueda
/// sincronizado con el estado del bloc al volver a la pantalla.
class StudentDirectory extends StatefulWidget {
  const StudentDirectory({super.key});

  @override
  State<StudentDirectory> createState() => _StudentDirectoryState();
}

class _StudentDirectoryState extends State<StudentDirectory> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AlumnosBloc>().state;
    final query = state is AlumnosLoaded ? state.searchQuery : '';
    _searchController = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportToCsv(List<Student> students) async {
    List<List<dynamic>> rows = [];

    // Encabezados
    rows.add([
      "Nombre",
      "Email",
      "Plan",
      "Estado",
      "Próximo Turno",
      "Clase",
      "Fecha de Ingreso"
    ]);

    // Filas de datos
    for (var s in students) {
      rows.add([
        s.name,
        s.email,
        s.plan,
        s.isActive ? "Activo" : "Inactivo",
        s.nextShift,
        s.shiftClass,
        s.createdAt.toIso8601String().split('T')[0],
      ]);
    }

    // Convertir a CSV e inyectar BOM para que Excel detecte UTF-8
    String csvData = const ListToCsvConverter().convert(rows);
    final bom = [0xEF, 0xBB, 0xBF]; // Byte Order Mark para UTF-8
    final bytes = Uint8List.fromList([...bom, ...utf8.encode(csvData)]);

    // Formatear la fecha actual para el nombre del archivo
    final dateStr = DateTime.now().toIso8601String().split('T')[0];

    try {
      await FileSaver.instance.saveFile(
        name: "alumnos_kali_$dateStr",
        bytes: bytes,
        ext: "csv",
        mimeType: MimeType.csv,
      );
    } catch (e) {
      debugPrint("Error exportando CSV: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocBuilder<AlumnosBloc, AlumnosState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: kaliColors.warmWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kaliColors.espresso.withValues(alpha: 0.05),
                blurRadius: 10,
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
                    style: kaliColors.body(Theme.of(context)
                        .extension<KaliColorsExtension>()!
                        .espresso),
                  ),
                ),
              ),

            // ── Datos listos ───────────────────────────────────────────────
            AlumnosLoaded() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state, _searchController),
                  if (state.students.isEmpty)
                    const KaliEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'Aún no hay alumnos registrados',
                      subtitle:
                          'Añadí tu primer alumno para comenzar a gestionar tu comunidad.',
                    )
                  else if (state.filteredStudents.isEmpty)
                    const KaliEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No se encontraron alumnos',
                      subtitle: 'Intenta ajustando los filtros de búsqueda.',
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double minWidth = 680.0;
                        final tableRows = Column(
                          children: [
                            _buildColumnHeaders(),
                            ...state.pageStudents
                                .map((s) => StudentRow(student: s)),
                          ],
                        );
                        if (constraints.maxWidth < minWidth) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: minWidth, child: tableRows),
                          );
                        }
                        return tableRows;
                      },
                    ),
                    KaliPagination(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      showingCount: state.pageStudents.length,
                      totalCount: state.filteredStudents.length,
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
  Widget _buildHeader(BuildContext context, AlumnosLoaded state,
      TextEditingController searchController) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final hasFilters = state.searchQuery.isNotEmpty ||
        state.patologiaFilter != null ||
        state.isActiveFilter != null;

    final searchField = SizedBox(
      height: 40,
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          context.read<AlumnosBloc>().add(AlumnosFilterChanged(
                searchQuery: value,
                patologiaFilter: state.patologiaFilter,
                isActiveFilter: state.isActiveFilter,
              ));
        },
        style: kaliColors.body(kaliColors.espresso, size: 14),
        decoration: InputDecoration(
          hintText: 'Buscar alumno...',
          hintStyle: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.4),
              size: 14),
          prefixIcon: Icon(Icons.search,
              size: 18, color: kaliColors.espresso.withValues(alpha: 0.4)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: kaliColors.warmWhite,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: kaliColors.espresso.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: kaliColors.espresso.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kaliColors.espresso)),
        ),
      ),
    );

    final actionIcons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KaliIconButton(
          Icons.tune_rounded,
          tooltip: 'Filtrar',
          color: hasFilters ? kaliColors.clayDark : null,
          onTap: () => showDialog(
              context: context,
              builder: (_) => AlumnosFilterDialog(state: state)),
        ),
        const SizedBox(width: 8),
        KaliIconButton(
          Icons.download_rounded,
          tooltip: 'Exportar CSV',
          onTap: () => _exportToCsv(state.filteredStudents),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 550;
        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Directorio de Alumnos',
                    style: kaliColors.headingItalic(kaliColors.espresso,
                        size: 20)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    actionIcons,
                  ],
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Directorio de Alumnos',
                  style:
                      kaliColors.headingItalic(kaliColors.espresso, size: 22)),
              Row(
                children: [
                  SizedBox(width: 250, child: searchField),
                  const SizedBox(width: 16),
                  actionIcons,
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Encabezados de columna ─────────────────────────────────────────────────
  Widget _buildColumnHeaders() {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final style = kaliColors.label(Theme.of(context)
        .extension<KaliColorsExtension>()!
        .espresso
        .withValues(alpha: 0.45));
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('NOMBRE', style: style)),
          Expanded(flex: 3, child: Text('PATOLOGÍAS', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 2, child: Text('ASISTENCIAS', style: style)),
          Expanded(flex: 2, child: Text('PRÓXIMO TURNO', style: style)),
          Expanded(flex: 2, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}
