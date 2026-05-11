import 'package:flutter/material.dart';
import 'package:kali_studio/models/schedule_template.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTemplateDialog extends StatefulWidget {
  final ScheduleTemplate? templateToEdit;

  const CreateTemplateDialog({super.key, this.templateToEdit});

  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _error;

  String _name = '';
  String? _instructor;
  int _capacity = 6;
  Set<String> _selectedDays = {'monday'};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _description;

  final List<String> _daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.templateToEdit != null) {
      final t = widget.templateToEdit!;
      _name = t.name;
      _description = t.description;
      _instructor = t.instructorName;
      _capacity = t.capacity;
      _selectedDays = {t.dayOfWeek.toLowerCase()};
      
      final startParts = t.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      
      final endParts = t.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    }
  }

  bool get isEditing => widget.templateToEdit != null;

  String _dayLabel(String englishDay) {
    switch (englishDay) {
      case 'monday': return 'Lunes';
      case 'tuesday': return 'Martes';
      case 'wednesday': return 'Miércoles';
      case 'thursday': return 'Jueves';
      case 'friday': return 'Viernes';
      case 'saturday': return 'Sábado';
      case 'sunday': return 'Domingo';
      default: return englishDay;
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un día')));
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = await Supabase.instance.client.from('profiles').select('institution_id').eq('id', user!.id).maybeSingle();
      final instId = profile?['institution_id'];

      if (isEditing) {
        await Supabase.instance.client.from('schedule_templates').update({
          'name': _name,
          'description': _description,
          'start_time': _formatTime(_startTime),
          'end_time': _formatTime(_endTime),
          'capacity': _capacity,
          'instructor_name': _instructor,
        }).eq('id', widget.templateToEdit!.id);
      } else {
        final payload = _selectedDays.map((day) => {
          'name': _name,
          'description': _description,
          'day_of_week': day, 
          'start_time': _formatTime(_startTime),
          'end_time': _formatTime(_endTime),
          'capacity': _capacity,
          'instructor_name': _instructor,
          'is_active': true,
          if (instId != null) 'institution_id': instId,
        }).toList();

        await Supabase.instance.client.from('schedule_templates').insert(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Plantilla actualizada' : 'Plantillas creadas exitosamente')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al guardar la plantilla: $e';
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Plantilla' : 'Nueva Plantilla de Clase',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing ? 'Modificando la información para futuros turnos agendados con esta plantilla.' : 'Crea esquemas reutilizables para agendar turnos fácilmente.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),

                // Name
                Text('Nombre de la Clase', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _name,
                  decoration: _inputDecoration('Ej. Reformer Funcional'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 16),

                // Instructor
                Text('Instructor', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _instructor,
                  decoration: _inputDecoration('Ej. Micaela'),
                  onSaved: (v) => _instructor = v?.isEmpty == true ? null : v,
                ),
                const SizedBox(height: 16),

                // Capacity
                Text('Capacidad (Aforo)', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _capacity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Ej. 6'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Número inválido' : null,
                  onSaved: (v) => _capacity = int.parse(v!),
                ),
                const SizedBox(height: 16),

                // Multi-select days
                Text('Días de la Semana', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _daysOfWeek.map((d) {
                    final isSelected = _selectedDays.contains(d);
                    return FilterChip(
                      label: Text(
                        _dayLabel(d),
                        style: KaliText.body(
                          isSelected ? Colors.white : KaliColors.espresso,
                          weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: isEditing ? null : (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(d);
                          } else if (_selectedDays.length > 1) { // Prevents removing the last remaining day
                            _selectedDays.remove(d);
                          }
                        });
                      },
                      selectedColor: KaliColors.espresso,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? KaliColors.espresso : KaliColors.espresso.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Times
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hora de Inicio', style: KaliText.label(KaliColors.espresso)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: KaliColors.espresso.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_formatTime(_startTime)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hora de Fin', style: KaliText.label(KaliColors.espresso)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: KaliColors.espresso.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_formatTime(_endTime)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancelar', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KaliColors.espresso,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Guardar Plantilla', style: KaliText.body(Colors.white, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
