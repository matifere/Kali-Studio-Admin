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
  
  List<ScheduleTemplate> _templates = [];
  bool _isLoadingTemplates = true;
  String? _error;

  ScheduleTemplate? _selectedTemplate;
  DateTime? _selectedDate;
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
        setState(() {
          _templates = response
              .map<ScheduleTemplate>((data) => ScheduleTemplate.fromJson(data))
              .toList();
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
    if (_formKey.currentState!.validate() && _selectedTemplate != null && _selectedDate != null) {
      // 1. Check if past
      final parts = _selectedTemplate!.startTime.split(':');
      final startDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 
        int.parse(parts[0]), int.parse(parts[1])
      );

      if (startDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes agendar un turno en el pasado.')),
        );
        return;
      }

      // 2. Check basic overlapping logic locally (only checks first week conceptually since subsequent occur next weeks)
      final sessions = context.read<TurnosBloc>().state.sessions;
      final newStartMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final endParts = _selectedTemplate!.endTime.split(':');
      final newEndMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      final hasOverlap = sessions.any((session) {
        if (session.date.year != _selectedDate!.year || 
            session.date.month != _selectedDate!.month || 
            session.date.day != _selectedDate!.day) {
          return false;
        }
        
        final existingStartParts = session.startTime.split(':');
        final existingEndParts = session.endTime.split(':');
        final existingStartMins = int.parse(existingStartParts[0]) * 60 + int.parse(existingStartParts[1]);
        final existingEndMins = int.parse(existingEndParts[0]) * 60 + int.parse(existingEndParts[1]);
        
        return newStartMins < existingEndMins && newEndMins > existingStartMins;
      });

      if (hasOverlap) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un turno en este mismo horario esta semana. Revísalo antes de crear múltiples.')),
        );
        return;
      }

      // Dispatch TurnoCreated
      context.read<TurnosBloc>().add(TurnoCreated(
        template: _selectedTemplate!, 
        date: _selectedDate!,
        recurrenceWeeks: _recurrenceWeeks,
      ));
      
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un template válido')),
      );
    }
  }

  void _onTemplateSelected(ScheduleTemplate? template) {
    if (template == null) return;
    final currentWeekStart = context.read<TurnosBloc>().state.currentWeekStart;
    final targetDate = currentWeekStart.add(Duration(days: template.dayIndex));
    
    setState(() {
      _selectedTemplate = template;
      _selectedDate = targetDate;
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
                  Text('Plantilla de Clase', style: KaliText.label(KaliColors.espresso)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ScheduleTemplate>(
                    value: _selectedTemplate,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Seleccionar plantilla'),
                    items: _templates.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.name} (${t.startTime.substring(0,5)} - ${t.endTime.substring(0,5)}) - ${t.dayNameSpanish}'),
                      );
                    }).toList(),
                    onChanged: _onTemplateSelected,
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  
                  const SizedBox(height: 20),

                  // Auto-calculated Date
                  Text('Fecha Autocalculada', style: KaliText.label(KaliColors.espresso)),
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
                        Text(
                          _selectedDate == null 
                            ? 'Esperando selección de plantilla...' 
                            : DateFormat("EEEE dd 'de' MMMM", "es_ES").format(_selectedDate!),
                          style: KaliText.body(
                            KaliColors.espresso,
                            weight: _selectedDate == null ? FontWeight.w400 : FontWeight.w600,
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
                      DropdownMenuItem(value: 1, child: Text('Solo esta semana (1 clase)')),
                      DropdownMenuItem(value: 4, child: Text('Mismo día / Todo el mes (4 clases)')),
                      DropdownMenuItem(value: 8, child: Text('Mismo día / Dos meses (8 clases)')),
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
                        child: Text('Crear Turno', style: KaliText.body(Colors.white, weight: FontWeight.w600)),
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
