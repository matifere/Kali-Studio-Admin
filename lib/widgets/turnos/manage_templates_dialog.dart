import 'package:flutter/material.dart';
import 'package:argrity/models/schedule_template.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/turnos/create_template_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageTemplatesDialog extends StatefulWidget {
  const ManageTemplatesDialog({super.key});

  @override
  State<ManageTemplatesDialog> createState() => _ManageTemplatesDialogState();
}

class _ManageTemplatesDialogState extends State<ManageTemplatesDialog> {
  List<ScheduleTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String? _selectedDay;

  static const _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  static const _dayLabels = {
    'monday': 'Lunes', 'tuesday': 'Martes', 'wednesday': 'Miércoles',
    'thursday': 'Jueves', 'friday': 'Viernes', 'saturday': 'Sábado', 'sunday': 'Domingo',
  };

  List<ScheduleTemplate> get _filteredTemplates {
    return _templates.where((t) {
      final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDay = _selectedDay == null || t.dayOfWeek.toLowerCase() == _selectedDay;
      return matchesSearch && matchesDay;
    }).toList();
  }

  Map<String, List<ScheduleTemplate>> get _groupedTemplates {
    final filtered = _filteredTemplates;
    final map = <String, List<ScheduleTemplate>>{};
    for (final t in filtered) {
      map.putIfAbsent(t.name, () => []).add(t);
    }
    // Sort each group's entries by day order
    for (final group in map.values) {
      group.sort((a, b) => _dayOrder.indexOf(a.dayOfWeek.toLowerCase())
          .compareTo(_dayOrder.indexOf(b.dayOfWeek.toLowerCase())));
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await Supabase.instance.client
          .from('schedule_templates')
          .select()
          .eq('is_active', true)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      if (mounted) {
        setState(() {
          _templates = response
              .map<ScheduleTemplate>((data) => ScheduleTemplate.fromJson(data))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando plantillas: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTemplateGroup(List<ScheduleTemplate> group) async {
    final name = group.first.name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('¿Seguro que deseas eliminar "$name"? Las clases ya agendadas de este tipo no se borrarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ids = group.map((t) => t.id).toList();
      await Supabase.instance.client
          .from('schedule_templates')
          .update({'is_active': false})
          .inFilter('id', ids);

      _loadTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocurrió un error inesperado. Intentá nuevamente.')));
      }
    }
  }

  void _openCreateOrEdit([ScheduleTemplate? template]) async {
    await showDialog(
      context: context,
      builder: (_) => CreateTemplateDialog(templateToEdit: template),
    );
    _loadTemplates(); // refresh after creating/editing
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Administración de Plantillas',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona las clases semanales para crear turnos rápidamente.',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            
            // Botón de crear nueva y filtros
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openCreateOrEdit(),
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: Text('Nueva Plantilla', style: KaliText.body(Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaliColors.espresso,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar plantilla...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedDay,
                    hint: const Text('Día'),
                    underline: const SizedBox(),
                    onChanged: (val) => setState(() => _selectedDay = val),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos los días')),
                      DropdownMenuItem(value: 'monday', child: Text('Lunes')),
                      DropdownMenuItem(value: 'tuesday', child: Text('Martes')),
                      DropdownMenuItem(value: 'wednesday', child: Text('Miércoles')),
                      DropdownMenuItem(value: 'thursday', child: Text('Jueves')),
                      DropdownMenuItem(value: 'friday', child: Text('Viernes')),
                      DropdownMenuItem(value: 'saturday', child: Text('Sábado')),
                      DropdownMenuItem(value: 'sunday', child: Text('Domingo')),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _filteredTemplates.isEmpty
                    ? Center(child: Text('No hay plantillas que coincidan con la búsqueda.', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5))))
                    : ListView(
                        children: _groupedTemplates.entries.map((entry) {
                          final name = entry.key;
                          final group = entry.value;
                          final days = group
                              .map((t) => _dayLabels[t.dayOfWeek.toLowerCase()] ?? t.dayOfWeek)
                              .join(', ');
                          final representative = group.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                                title: Text(name, style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600)),
                                subtitle: Text(
                                  '$days • ${representative.startTime.substring(0,5)} - ${representative.endTime.substring(0,5)} • Cap: ${representative.capacity}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _openCreateOrEdit(representative),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () => _deleteTemplateGroup(group),
                                      tooltip: 'Desactivar',
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: KaliColors.espresso.withValues(alpha: 0.08)),
                            ],
                          );
                        }).toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
