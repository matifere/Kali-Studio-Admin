import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:intl/intl.dart';

/// Diálogo para marcar un rango de vacaciones/feriado: cancela todas las clases
/// comprendidas entre la fecha de inicio y la de fin (inclusive). El admin
/// puede elegir si se devuelve el crédito a cada alumno inscripto o si la clase
/// se pierde (la reserva queda como ausente y no libera cupo).
class AddHolidayDialog extends StatefulWidget {
  const AddHolidayDialog({super.key});

  @override
  State<AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _refundCredits = true;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      // La fecha de fin no puede ser anterior a la de inicio.
      firstDate: isStart ? firstDate : _startDate,
      lastDate: DateTime(now.year + 1, 12, 31),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Mantener el fin coherente con el inicio.
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    context.read<TurnosBloc>().add(HolidayAdded(
          date: _startDate,
          endDate: _endDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          refundCredits: _refundCredits,
        ));
    Navigator.of(context).pop();
  }

  String _formatLong(DateTime date) {
    final s = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date);
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isRange = _startDate.year != _endDate.year ||
        _startDate.month != _endDate.month ||
        _startDate.day != _endDate.day;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kaliColors.warmWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agregar Vacaciones / Feriado',
                  style: kaliColors.heading(kaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se cancelarán todas las clases del período elegido. Elegí si '
                  'se devuelve el crédito a cada alumno inscripto o si la clase '
                  'se pierde.',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Desde',
                        value: _formatLong(_startDate),
                        onTap: () => _pickDate(isStart: true),
                        kaliColors: kaliColors,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Hasta',
                        value: _formatLong(_endDate),
                        onTap: () => _pickDate(isStart: false),
                        kaliColors: kaliColors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Selector de qué hacer con los créditos.
                Container(
                  decoration: BoxDecoration(
                    color: kaliColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _refundCredits,
                    onChanged: (v) => setState(() => _refundCredits = v),
                    activeThumbColor: kaliColors.espresso,
                    title: Text(
                      _refundCredits
                          ? 'Devolver créditos a los alumnos'
                          : 'Las clases se pierden',
                      style: kaliColors.label(kaliColors.espresso),
                    ),
                    subtitle: Text(
                      _refundCredits
                          ? 'No cuenta como clase perdida; el alumno recupera el cupo.'
                          : 'La reserva queda como ausente y no libera cupo mensual.',
                      style: kaliColors
                          .body(kaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Motivo (Opcional)',
                    style: kaliColors.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                TextField(
                  style: kaliColors.body(kaliColors.espresso),
                  controller: _reasonController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kaliColors.background,
                    hintStyle: kaliColors
                        .body(kaliColors.espresso.withValues(alpha: 0.65)),
                    hintText: 'Ej. Vacaciones de invierno',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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
                      child: Text(
                          isRange
                              ? 'Cancelar Clases del Período'
                              : 'Cancelar Clases del Día',
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
}

/// Campo de fecha con estilo consistente (label + caja seleccionable).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.kaliColors,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final KaliColorsExtension kaliColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kaliColors.label(kaliColors.espresso)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: kaliColors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18,
                    color: kaliColors.espresso.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: kaliColors.body(kaliColors.espresso),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
