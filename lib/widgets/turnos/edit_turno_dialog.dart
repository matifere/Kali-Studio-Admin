import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/turnos/turnos_bloc.dart';
import 'package:kali_studio/models/class_session.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:intl/intl.dart';

class EditTurnoDialog extends StatefulWidget {
  final ClassSession turno;

  const EditTurnoDialog({super.key, required this.turno});

  @override
  State<EditTurnoDialog> createState() => _EditTurnoDialogState();
}

class _EditTurnoDialogState extends State<EditTurnoDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String? _instructor;
  late int _capacity;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String? _description;

  @override
  void initState() {
    super.initState();
    final t = widget.turno;
    _name = t.name;
    _instructor = t.instructorName;
    _capacity = t.capacity;
    _date = t.date;
    _description = t.description;

    final startParts = t.startTime.split(':');
    _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));

    final endParts = t.endTime.split(':');
    _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final updatedTurno = ClassSession(
      id: widget.turno.id,
      templateId: widget.turno.templateId,
      name: _name,
      description: _description,
      date: _date,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      capacity: _capacity,
      enrolled: widget.turno.enrolled,
      instructorName: _instructor,
      status: widget.turno.status,
    );

    context.read<TurnosBloc>().add(TurnoEdited(updatedTurno));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turno actualizado existosamente')));
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
                  'Editar Turno',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si editas la fecha u horario, asegúrate de avisar a los alumnos inscriptos.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),

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
                  validator: (v) {
                    final c = int.tryParse(v ?? '');
                    if (c == null) return 'Número inválido';
                    if (c < widget.turno.enrolled) return 'No puede ser menor a los inscriptos (${widget.turno.enrolled})';
                    return null;
                  },
                  onSaved: (v) => _capacity = int.parse(v!),
                ),
                const SizedBox(height: 16),

                // Date
                Text('Fecha', style: KaliText.label(KaliColors.espresso)),
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
                          DateFormat("EEEE dd 'de' MMMM", "es_ES").format(_date),
                          style: KaliText.body(KaliColors.espresso),
                        ),
                        Icon(Icons.calendar_month_outlined, color: KaliColors.espresso.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
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
                      child: Text('Guardar Modificaciones', style: KaliText.body(Colors.white, weight: FontWeight.w600)),
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
