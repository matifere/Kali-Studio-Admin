import 'package:flutter/material.dart';
import 'package:kali_studio/models/schedule_template.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/turnos/create_template_dialog.dart';
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

  List<ScheduleTemplate> get _filteredTemplates {
    return _templates.where((t) {
      final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDay = _selectedDay == null || t.dayOfWeek.toLowerCase() == _selectedDay;
      return matchesSearch && matchesDay;
    }).toList();
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

  Future<void> _deleteTemplate(ScheduleTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('¿Seguro que deseas eliminar la clase ${template.name}? Las clases ya agendadas de este tipo no se borrarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('schedule_templates')
          .update({'is_active': false})
          .eq('id', template.id);
      
      _loadTemplates();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        width: 700,
        height: 600,
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
                    : ListView.separated(
                        itemCount: _filteredTemplates.length,
                        separatorBuilder: (_, __) => Divider(color: KaliColors.espresso.withValues(alpha: 0.1)),
                        itemBuilder: (context, index) {
                          final t = _filteredTemplates[index];
                          return ListTile(
                            title: Text(t.name, style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600)),
                            subtitle: Text('${t.dayNameSpanish} • ${t.startTime.substring(0,5)} - ${t.endTime.substring(0,5)} • Cap: ${t.capacity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openCreateOrEdit(t),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteTemplate(t),
                                  tooltip: 'Desactivar',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
