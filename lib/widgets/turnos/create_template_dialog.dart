import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:argrity/models/schedule_template.dart';
import 'package:argrity/theme/kali_theme.dart';
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
  List<String> _instructorNames = [];
  bool _loadingInstructors = true;
  int _capacity = 6;
  Set<String> _selectedDays = {'monday'};
  final TextEditingController _startTimeCtrl = TextEditingController(text: '09:00');
  final TextEditingController _endTimeCtrl = TextEditingController(text: '10:00');
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
      _startTimeCtrl.text = t.startTime.substring(0, 5);
      _endTimeCtrl.text = t.endTime.substring(0, 5);
    }
    _loadInstructors();
  }

  @override
  void dispose() {
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('role', 'admin')
          .order('full_name', ascending: true);

      final names = (res as List)
          .map((p) => p['full_name'] as String?)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _instructorNames = names;
          _loadingInstructors = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInstructors = false);
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

  bool _isValidTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un día')));
      return;
    }
    if (!_isValidTime(_startTimeCtrl.text)) {
      setState(() => _error = 'Hora de inicio inválida. Usá el formato HH:MM');
      return;
    }
    if (!_isValidTime(_endTimeCtrl.text)) {
      setState(() => _error = 'Hora de fin inválida. Usá el formato HH:MM');
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
          'start_time': _startTimeCtrl.text,
          'end_time': _endTimeCtrl.text,
          'capacity': _capacity,
          'instructor_name': _instructor,
        }).eq('id', widget.templateToEdit!.id);
      } else {
        final payload = _selectedDays.map((day) => {
          'name': _name,
          'description': _description,
          'day_of_week': day,
          'start_time': _startTimeCtrl.text,
          'end_time': _endTimeCtrl.text,
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
                _loadingInstructors
                    ? const SizedBox(
                        height: 52,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _instructorNames.contains(_instructor) ? _instructor : null,
                        decoration: _inputDecoration('Selecciona un instructor'),
                        items: _instructorNames
                            .map((name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name, style: KaliText.body(KaliColors.espresso)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _instructor = v),
                        onSaved: (v) => _instructor = v,
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
                          } else if (_selectedDays.length > 1) {
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
                          TextField(
                            controller: _startTimeCtrl,
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            decoration: _inputDecoration('HH:MM'),
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
                          TextField(
                            controller: _endTimeCtrl,
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            decoration: _inputDecoration('HH:MM'),
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
