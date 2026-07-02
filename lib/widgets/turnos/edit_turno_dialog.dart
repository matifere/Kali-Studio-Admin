import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _editFutureSessions = false;

  List<String> _instructors = [];
  bool _isLoadingInstructors = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    final t = widget.turno;
    _name = t.name;
    _instructor = t.instructorName;
    _capacity = t.capacity;
    _date = t.date;
    _description = t.description;

    final startParts = t.startTime.split(':');
    _startTime = TimeOfDay(
        hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));

    final endParts = t.endTime.split(':');
    _endTime =
        TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
  }

  Future<void> _loadInstructors() async {
    try {
      // Filtrar por institución para no mezclar entrenadores de otros estudios.
      final instId = ProfileCache.institutionId;

      var query = Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .inFilter('role', const ['admin', 'sudo']);

      if (instId != null) {
        query = query.eq('institution_id', instId);
      }

      final res = await query.order('full_name', ascending: true);
      final list = (res as List).map((e) => e['full_name'] as String).toList();

      if (mounted) {
        setState(() {
          _instructors = list;
          _isLoadingInstructors = false;
          if (_instructor != null && !_instructors.contains(_instructor)) {
            _instructors.add(_instructor!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInstructors = false;
        });
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
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
      groupId: widget.turno.groupId,
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

    context.read<TurnosBloc>().add(
        TurnoEdited(updatedTurno, editFutureSessions: _editFutureSessions));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno actualizado existosamente')));
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kaliColors.warmWhite,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
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
                  style: kaliColors.heading(kaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si editas la fecha u horario, asegúrate de avisar a los alumnos inscriptos.',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),

                // Name
                Text('Nombre de la Clase',
                    style: kaliColors.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  style: kaliColors.body(kaliColors.espresso),
                  initialValue: _name,
                  decoration:
                      _inputDecoration('Ej. Reformer Funcional', kaliColors),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 16),

                // Instructor
                Text('Instructor',
                    style: kaliColors.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                _isLoadingInstructors
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        style: kaliColors.body(kaliColors.espresso),
                        initialValue: _instructor,
                        hint: const Text('Sin instructor'),
                        decoration:
                            _inputDecoration('Seleccionar...', kaliColors),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Sin instructor')),
                          ..._instructors.map((e) =>
                              DropdownMenuItem(value: e, child: Text(e))),
                        ],
                        onChanged: (val) {
                          setState(() => _instructor = val);
                        },
                      ),
                const SizedBox(height: 16),

                // Capacity
                Text('Capacidad (Aforo)',
                    style: kaliColors.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  style: kaliColors.body(kaliColors.espresso),
                  initialValue: _capacity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Ej. 6', kaliColors),
                  validator: (v) {
                    final c = int.tryParse(v ?? '');
                    if (c == null) return 'Número inválido';
                    if (c < widget.turno.enrolled)
                      return 'No puede ser menor a los inscriptos (${widget.turno.enrolled})';
                    return null;
                  },
                  onSaved: (v) => _capacity = int.parse(v!),
                ),
                const SizedBox(height: 16),

                // Date
                Text('Fecha', style: kaliColors.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: kaliColors.background,
                      border: Border.all(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat("EEEE dd 'de' MMMM", "es_ES")
                              .format(_date),
                          style: kaliColors.body(kaliColors.espresso),
                        ),
                        Icon(Icons.calendar_month_outlined,
                            color: kaliColors.espresso.withValues(alpha: 0.5)),
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
                          Text('Hora de Inicio',
                              style: kaliColors.label(kaliColors.espresso)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: kaliColors.background,
                                border: Border.all(
                                    color: kaliColors.espresso
                                        .withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_formatTime(_startTime),
                                  style: kaliColors.body(kaliColors.espresso)),
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
                          Text('Hora de Fin',
                              style: kaliColors.label(kaliColors.espresso)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: kaliColors.background,
                                border: Border.all(
                                    color: kaliColors.espresso
                                        .withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_formatTime(_endTime),
                                  style: kaliColors.body(kaliColors.espresso)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (widget.turno.groupId != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: kaliColors.sand.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                    ),
                    child: CheckboxListTile(
                      title: Text('Modificar turnos futuros también',
                          style: kaliColors.body(kaliColors.espresso,
                              weight: FontWeight.w600)),
                      subtitle: Text(
                          'Aplica los cambios a todos los turnos de este grupo en la misma franja horaria hacia adelante.',
                          style: kaliColors.body(
                              kaliColors.espresso.withValues(alpha: 0.6),
                              size: 12)),
                      value: _editFutureSessions,
                      activeColor: kaliColors.espresso,
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _editFutureSessions = val);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar',
                          style: kaliColors.body(
                              kaliColors.espresso.withValues(alpha: 0.6))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kaliColors.espresso,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Guardar Modificaciones',
                          style: kaliColors.body(kaliColors.warmWhite,
                              weight: FontWeight.w600)),
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

  InputDecoration _inputDecoration(
      String hint, KaliColorsExtension kaliColors) {
    return InputDecoration(
      filled: true,
      fillColor: kaliColors.background,
      hintStyle: kaliColors.body(kaliColors.espresso.withValues(alpha: 0.5)),
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: kaliColors.espresso.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: kaliColors.espresso.withValues(alpha: 0.1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
