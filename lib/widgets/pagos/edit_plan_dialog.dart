import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dialog que presenta el formulario de edición de un plan existente.
class EditPlanDialog extends StatefulWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onRefresh;

  const EditPlanDialog({super.key, required this.plan, required this.onRefresh});

  @override
  State<EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<EditPlanDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _error;

  late String _name;
  String? _description;
  late double _price;
  late String _currency;
  late int _maxReservationsPerWeek;
  late bool _isActive;

  final List<String> _currencies = ['ARS', 'USD'];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = p['name'] ?? '';
    _description = p['description'];
    _price = (p['price'] as num?)?.toDouble() ?? 0.0;
    _currency = p['currency'] ?? 'ARS';
    _maxReservationsPerWeek = (p['max_reservations_per_week'] as num?)?.toInt() ?? 2;
    _isActive = p['is_active'] ?? true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payload = {
        'name': _name,
        'description': _description,
        'price': _price,
        'currency': _currency,
        'max_reservations_per_week': _maxReservationsPerWeek,
        'is_active': _isActive,
      };

      await Supabase.instance.client
          .from('plans')
          .update(payload)
          .eq('id', widget.plan['id']);

      if (mounted) {
        widget.onRefresh();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan actualizado exitosamente')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al actualizar el plan: $e';
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
                  'Editar Plan',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica los datos del plan de pagos.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),

                // Name
                Text('Nombre del Plan', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _name,
                  decoration: _inputDecoration('Ej. Plan Mensual 2x'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 16),

                // Description
                Text('Descripción (Opcional)', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _description,
                  maxLines: 2,
                  decoration: _inputDecoration('Ej. Permite hasta 2 reservas por semana'),
                  onSaved: (v) => _description = v?.isEmpty == true ? null : v,
                ),
                const SizedBox(height: 16),

                // Price and Currency
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Precio', style: KaliText.label(KaliColors.espresso)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _price.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('Ej. 25000'),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Número inválido' : null,
                            onSaved: (v) => _price = double.parse(v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Moneda', style: KaliText.label(KaliColors.espresso)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: _inputDecoration('ARS'),
                            items: _currencies.map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(c, style: KaliText.body(KaliColors.espresso)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max reservations per week
                Text('Máximo de Reservas por Semana', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _maxReservationsPerWeek.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Ej. 2'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Número inválido' : null,
                  onSaved: (v) => _maxReservationsPerWeek = int.parse(v!),
                ),
                const SizedBox(height: 16),

                // Is Active
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: Text('Plan Activo', style: KaliText.body(KaliColors.espresso, size: 14)),
                  subtitle: Text('Determina si el plan está disponible.', style: KaliText.caption(KaliColors.espresso.withValues(alpha: 0.6))),
                  activeColor: KaliColors.espresso,
                  contentPadding: EdgeInsets.zero,
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Guardar Cambios',
                              style: KaliText.body(Colors.white,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: KaliColors.espresso.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: KaliColors.espresso.withValues(alpha: 0.1)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
