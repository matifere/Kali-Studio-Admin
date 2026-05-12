import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dialog que presenta el formulario de creación de un nuevo plan.
class CreatePlanDialog extends StatefulWidget {
  const CreatePlanDialog({super.key});

  @override
  State<CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<CreatePlanDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _error;

  String _name = '';
  String? _description;
  double _price = 0.0;
  String _currency = 'ARS';
  int _maxReservationsPerWeek = 2;
  bool _isActive = true;

  final List<String> _currencies = ['ARS', 'USD'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;
      final profile = await db.from('profiles').select('institution_id').eq('id', user!.id).maybeSingle();
      final instId = profile?['institution_id'];

      final payload = {
        'name': _name,
        'description': _description,
        'price': _price,
        'currency': _currency,
        'max_reservations_per_week': _maxReservationsPerWeek,
        'is_active': _isActive,
        if (instId != null) 'institution_id': instId,
      };

      await db.from('plans').insert(payload);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan creado exitosamente')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al guardar el plan: $e';
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
                  'Crear Nuevo Plan',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Define un plan de pagos para los alumnos del estudio.',
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
                  decoration: _inputDecoration('Ej. Plan Mensual 2x'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 16),

                // Description
                Text('Descripción (Opcional)', style: KaliText.label(KaliColors.espresso)),
                const SizedBox(height: 8),
                TextFormField(
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
                  initialValue: '2',
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
                          : Text('Guardar Plan',
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
