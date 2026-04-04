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

      setState(() {
        _templates = response
            .map<ScheduleTemplate>((data) => ScheduleTemplate.fromJson(data))
            .toList();
        _isLoadingTemplates = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load templates: $e';
        _isLoadingTemplates = false;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedTemplate != null && _selectedDate != null) {
      // Dispatch TurnoCreated
      context.read<TurnosBloc>().add(TurnoCreated(
        template: _selectedTemplate!, 
        date: _selectedDate!,
      ));
      
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un template y una fecha')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
                    'Selecciona una clase predefinida para agendar un turno.',
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
                  DropdownButton<ScheduleTemplate>(
                    value: _selectedTemplate,
                    isExpanded: true,
                    hint: const Text('Seleccionar plantilla'),
                    items: _templates.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.name} (${t.startTime} - ${t.endTime}) - ${t.dayNameSpanish}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTemplate = val;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // Date Picker
                  Text('Fecha de la Sesión', style: KaliText.label(KaliColors.espresso)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: KaliColors.espresso.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null 
                              ? 'Seleccionar fecha' 
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            style: KaliText.body(KaliColors.espresso),
                          ),
                          Icon(Icons.calendar_month_outlined, color: KaliColors.espresso.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
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
