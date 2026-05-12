import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/models/schedule_template.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CreateTurnoDialog extends StatefulWidget {
  const CreateTurnoDialog({super.key});

  @override
  State<CreateTurnoDialog> createState() => _CreateTurnoDialogState();
}

class _CreateTurnoDialogState extends State<CreateTurnoDialog> {
  final _formKey = GlobalKey<FormState>();
  
  List<List<ScheduleTemplate>> _templateGroups = [];
  bool _isLoadingTemplates = true;
  String? _error;

  List<ScheduleTemplate>? _selectedTemplates;
  int _recurrenceWeeks = 1;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final response = await Supabase.instance.client
          .from('schedule_templates')
          .select()
          .eq('is_active', true);

      if (mounted) {
        final allTemplates = response
            .map<ScheduleTemplate>((data) => ScheduleTemplate.fromJson(data))
            .toList();

        // Agrupar plantillas idénticas (mismo nombre, hora inicio, hora fin e instructor)
        final groupsMap = <String, List<ScheduleTemplate>>{};
        for (var t in allTemplates) {
          final key = '${t.name}_${t.startTime}_${t.endTime}_${t.instructorName ?? ""}';
          groupsMap.putIfAbsent(key, () => []).add(t);
        }

        setState(() {
          _templateGroups = groupsMap.values.toList();
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load templates: $e';
          _isLoadingTemplates = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedTemplates != null && _selectedTemplates!.isNotEmpty) {
      // Dispatch TurnoCreated con la lista de plantillas agrupadas
      context.read<TurnosBloc>().add(TurnoCreated(
        templates: _selectedTemplates!, 
        recurrenceWeeks: _recurrenceWeeks,
      ));
      
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una plantilla válida')),
      );
    }
  }

  void _onTemplateGroupSelected(List<ScheduleTemplate>? templates) {
    if (templates == null || templates.isEmpty) return;
    
    setState(() {
      _selectedTemplates = templates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: _isLoadingTemplates 
          ? const SizedBox(
              height: 200, 
              child: Center(child: CircularProgressIndicator())
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear Nuevo Turno',
                    style: KaliText.heading(KaliColors.espresso, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agendando para la semana en vista (${DateFormat("dd MMM", "es_ES").format(context.read<TurnosBloc>().state.currentWeekStart)}).',
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  
                  // Template Dropdown
                  Text('Plantilla de Clase (Días)', style: KaliText.label(KaliColors.espresso)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<List<ScheduleTemplate>>(
                    value: _selectedTemplates,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Seleccionar plantilla'),
                    items: _templateGroups.map((group) {
                      final first = group.first;
                      final daysStr = group.map((t) => t.dayNameSpanish.substring(0, 2)).join(', ');
                      return DropdownMenuItem(
                        value: group,
                        child: Text('${first.name} (${first.startTime.substring(0,5)} - ${first.endTime.substring(0,5)}) - [$daysStr]'),
                      );
                    }).toList(),
                    onChanged: _onTemplateGroupSelected,
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  
                  const SizedBox(height: 20),

                  // Auto-calculated Date info
                  Text('Días Seleccionados', style: KaliText.label(KaliColors.espresso)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: KaliColors.sand.withValues(alpha: 0.3),
                      border: Border.all(color: KaliColors.espresso.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: KaliColors.espresso.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedTemplates == null 
                              ? 'Esperando selección de plantilla...' 
                              : 'Se agendarán clases los días: ${_selectedTemplates!.map((t) => t.dayNameSpanish).join(', ')}.',
                            style: KaliText.body(
                              KaliColors.espresso,
                              weight: _selectedTemplates == null ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Frecuencia
                  Text('Frecuencia de Repetición', style: KaliText.label(KaliColors.espresso)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _recurrenceWeeks,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Solo esta semana (1 repetición)')),
                      DropdownMenuItem(value: 4, child: Text('Todo el mes (4 repeticiones)')),
                      DropdownMenuItem(value: 8, child: Text('Dos meses (8 repeticiones)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _recurrenceWeeks = val);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KaliColors.espresso,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Crear Turnos', style: KaliText.body(Colors.white, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
