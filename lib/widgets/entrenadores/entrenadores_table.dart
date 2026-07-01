import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/common/kali_icon_button.dart';
import 'package:argrity/widgets/entrenadores/add_trainer_button.dart';
import 'package:argrity/widgets/entrenadores/trainer_row.dart';

class EntrenadoresTable extends StatefulWidget {
  const EntrenadoresTable({super.key});

  @override
  State<EntrenadoresTable> createState() => _EntrenadoresTableState();
}

class _EntrenadoresTableState extends State<EntrenadoresTable> {
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Filtrar por institución para mostrar solo entrenadores de este estudio.
      final instId = ProfileCache.institutionId;

      var query = Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, is_active, role')
          .inFilter('role', const ['admin', 'sudo']);

      if (instId != null) {
        query = query.eq('institution_id', instId);
      }

      final res = await query.order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _trainers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar entrenadores: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onTrainerCreated(Map<String, dynamic> trainer) {
    setState(() {
      _trainers = [..._trainers, trainer]..sort((a, b) =>
          (a['full_name'] as String? ?? '')
              .compareTo(b['full_name'] as String? ?? ''));
    });
  }

  Future<void> _deleteTrainer(Map<String, dynamic> trainer) async {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar entrenador',
          style: KaliText.body(kaliColors.espresso,
              weight: FontWeight.w600, size: 18),
        ),
        content: Text(
          '¿Seguro que querés eliminar a ${trainer['full_name']}? Esta acción no se puede deshacer.',
          style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: KaliText.body(kaliColors.espresso)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: KaliText.body(const Color(0xFFD4685C),
                  weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deleted = await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', trainer['id'])
            .select('id');

        if (deleted.isEmpty) {
          throw Exception(
              'No se eliminó ningún registro. Verificá los permisos en Supabase.');
        }

        if (mounted) {
          _loadTrainers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrenador eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo eliminar el registro. Intentá nuevamente.'),
              duration: Duration(seconds: 8),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
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
          _buildHeader(kaliColors),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: LinearProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child:
                  Text(_error!, style: KaliText.body(const Color(0xFFD4685C))),
            )
          else if (_trainers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 40,
                      color: kaliColors.espresso.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay entrenadores registrados.',
                      style: KaliText.body(
                          kaliColors.espresso.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                const double minWidth = 600.0;
                final tableRows = Column(
                  children: [
                    _buildColumnHeaders(kaliColors),
                    ..._trainers.map((t) => TrainerRow(
                          trainer: t,
                          onDelete: () => _deleteTrainer(t),
                        )),
                    const SizedBox(height: 24),
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
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(KaliColorsExtension kaliColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Entrenadores del Estudio',
              style: KaliText.headingItalic(kaliColors.espresso, size: 22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          AddTrainerButton(onTrainerCreated: _onTrainerCreated),
          const SizedBox(width: 8),
          KaliIconButton(
            Icons.refresh_rounded,
            tooltip: 'Refrescar',
            onTap: _loadTrainers,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(KaliColorsExtension kaliColors) {
    final style = KaliText.label(kaliColors.espresso.withValues(alpha: 0.45));
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('NOMBRE', style: style)),
          Expanded(flex: 4, child: Text('CORREO', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 2, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}
