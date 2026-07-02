import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:intl/intl.dart';

/// Diálogo para marcar un día como feriado: cancela todas las clases de ese día
/// y devuelve el crédito a cada alumno inscripto.
class AddHolidayDialog extends StatefulWidget {
  const AddHolidayDialog({super.key});

  @override
  State<AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    context.read<TurnosBloc>().add(HolidayAdded(
          date: _selectedDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final fechaLarga =
        DateFormat("EEEE d 'de' MMMM", 'es_ES').format(_selectedDate);

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
                  'Agregar Feriado',
                  style: KaliText.heading(kaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se cancelarán todas las clases del día elegido y se devolverá '
                  'el crédito a cada alumno inscripto (no cuenta como clase perdida).',
                  style: KaliText.body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),

                Text('Fecha', style: KaliText.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(filled: true, fillColor: kaliColors.background,
                      hintStyle: KaliText.body(kaliColors.espresso.withValues(alpha: 0.5)),
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 18,
                            color: kaliColors.espresso.withValues(alpha: 0.6)),
                        const SizedBox(width: 12),
                        Text(
                          fechaLarga[0].toUpperCase() + fechaLarga.substring(1),
                          style: KaliText.body(kaliColors.espresso),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Motivo (Opcional)',
                    style: KaliText.label(kaliColors.espresso)),
                const SizedBox(height: 8),
                TextField(
                  style: KaliText.body(kaliColors.espresso),
                  controller: _reasonController,
                  decoration: InputDecoration(filled: true, fillColor: kaliColors.background,
                      hintStyle: KaliText.body(kaliColors.espresso.withValues(alpha: 0.5)),
                    hintText: 'Ej. Feriado nacional',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar',
                          style: KaliText.body(
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
                      child: Text('Cancelar Clases del Día',
                          style: KaliText.body(kaliColors.warmWhite,
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
