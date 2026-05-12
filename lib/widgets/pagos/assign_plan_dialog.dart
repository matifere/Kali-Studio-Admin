import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignPlanDialog extends StatefulWidget {
  const AssignPlanDialog({super.key});

  @override
  State<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends State<AssignPlanDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _plans = [];

  String? _selectedStudentId;
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // Cargar alumnos
      final studentsRes = await client
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'client')
          .order('full_name', ascending: true);

      // Cargar planes activos
      final plansRes = await client
          .from('plans')
          .select('id, name, price, currency')
          .eq('is_active', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(studentsRes);
          _plans = List<Map<String, dynamic>>.from(plansRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedPlanId == null) {
      setState(() => _error = 'Por favor selecciona un alumno y un plan.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30));

      final db = Supabase.instance.client;
      final user = db.auth.currentUser;
      final profile = await db.from('profiles').select('institution_id').eq('id', user!.id).maybeSingle();
      final instId = profile?['institution_id'];

      final payload = {
        'user_id': _selectedStudentId,
        'plan_id': _selectedPlanId,
        'status': 'pending', // El estado inicial siempre debe ser pendiente
        'start_date': startDate.toIso8601String().split('T')[0], // Fecha actual
        'end_date': endDate.toIso8601String().split('T')[0], // Se agrega fecha de fin (30 días por defecto)
        if (instId != null) 'institution_id': instId,
      };

      await db.from('subscriptions').insert(payload);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan asignado exitosamente (Pendiente)')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al asignar el plan: $e';
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
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asignar Plan',
                        style: KaliText.heading(KaliColors.espresso, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Asigna un plan a un estudiante. El estado inicial será "pendiente".',
                        style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),

                      // Seleccionar Alumno
                      Text('Alumno', style: KaliText.label(KaliColors.espresso)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: _inputDecoration('Selecciona un alumno'),
                        items: _students.map((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'] as String,
                            child: Text(
                              s['full_name'] ?? 'Sin nombre',
                              style: KaliText.body(KaliColors.espresso),
                            ),
                          );
                        }).toList(),
                        validator: (v) => v == null ? 'Requerido' : null,
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedStudentId = v);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Seleccionar Plan
                      Text('Plan', style: KaliText.label(KaliColors.espresso)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedPlanId,
                        decoration: _inputDecoration('Selecciona un plan'),
                        items: _plans.map((p) {
                          final name = p['name'] ?? 'Sin nombre';
                          final price = (p['price'] as num?)?.toDouble() ?? 0.0;
                          final currency = p['currency'] ?? 'ARS';
                          return DropdownMenuItem<String>(
                            value: p['id'] as String,
                            child: Text(
                              '$name - \$${price.toStringAsFixed(2)} $currency',
                              style: KaliText.body(KaliColors.espresso),
                            ),
                          );
                        }).toList(),
                        validator: (v) => v == null ? 'Requerido' : null,
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedPlanId = v);
                        },
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
                                : Text('Asignar Plan',
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
