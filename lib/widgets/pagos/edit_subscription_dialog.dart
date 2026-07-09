import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/pagos/pagos_bloc.dart';
import 'package:argrity/models/subscription.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dialog para editar una asignación de plan: permite cambiar el plan y las
/// fechas de inicio/fin de la suscripción.
class EditSubscriptionDialog extends StatefulWidget {
  final Subscription subscription;

  const EditSubscriptionDialog({super.key, required this.subscription});

  @override
  State<EditSubscriptionDialog> createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.subscription.planId;
    _startDate = widget.subscription.startDate;
    _endDate = widget.subscription.endDate;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plansRes = await Supabase.instance.client
          .from('plans')
          .select('id, name, price, currency')
          .eq('is_active', true)
          .order('name', ascending: true);

      final plans = List<Map<String, dynamic>>.from(plansRes);

      // Si el plan actual está inactivo no vendrá en la lista; lo agregamos
      // para poder preseleccionarlo y no perder la referencia al editar.
      final currentId = widget.subscription.planId;
      if (currentId != null && !plans.any((p) => p['id'] == currentId)) {
        plans.insert(0, {
          'id': currentId,
          'name': '${widget.subscription.planName} (inactivo)',
          'price': widget.subscription.price,
          'currency': widget.subscription.currency,
        });
      }

      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar planes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_selectedPlanId == null) {
      setState(() => _error = 'Seleccioná un plan.');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(
          () => _error = 'La fecha de fin no puede ser anterior al inicio.');
      return;
    }

    setState(() => _isSaving = true);

    final plan = _plans.firstWhere((p) => p['id'] == _selectedPlanId);

    context.read<PagosBloc>().add(
          PagosSubscriptionEdited(
            subscriptionId: widget.subscription.id,
            planId: _selectedPlanId!,
            planName: plan['name'] ?? widget.subscription.planName,
            price: (plan['price'] as num?)?.toDouble() ?? 0.0,
            currency: plan['currency'] ?? 'ARS',
            startDate: _startDate,
            endDate: _endDate,
          ),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Asignación actualizada')),
    );
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
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Asignación',
                      style: kaliColors.heading(kaliColors.espresso, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modificá el plan o las fechas de ${widget.subscription.studentName}.',
                      style: kaliColors
                          .body(kaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    // Plan
                    Text('Plan', style: kaliColors.label(kaliColors.espresso)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPlanId,
                      decoration:
                          _inputDecoration('Selecciona un plan', kaliColors),
                      items: _plans.map((p) {
                        final name = p['name'] ?? 'Sin nombre';
                        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
                        final currency = p['currency'] ?? 'ARS';
                        return DropdownMenuItem<String>(
                          value: p['id'] as String,
                          child: Text(
                            '$name - \$${price.toStringAsFixed(2)} $currency',
                            style: kaliColors.body(kaliColors.espresso),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPlanId = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fechas
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Inicio',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DateField(
                            label: 'Fin',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text('Cancelar',
                              style: kaliColors.body(
                                  kaliColors.espresso.withValues(alpha: 0.6))),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kaliColors.espresso,
                            foregroundColor: kaliColors
                                .getContrastColor(kaliColors.espresso),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Guardar Cambios',
                              style: kaliColors.body(
                                  kaliColors
                                      .getContrastColor(kaliColors.espresso),
                                  weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint, KaliColorsExtension kaliColors) {
    return InputDecoration(
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kaliColors.label(kaliColors.espresso)),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kaliColors.espresso.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(text, style: kaliColors.body(kaliColors.espresso)),
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: kaliColors.espresso.withValues(alpha: 0.65)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
