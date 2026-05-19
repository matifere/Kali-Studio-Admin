import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/bloc/alumnos/alumnos_bloc.dart';
import 'package:kali_studio/models/student.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditStudentDialog extends StatefulWidget {
  final Student student;

  const EditStudentDialog({super.key, required this.student});

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _patologiaController;
  late List<String> _patologias;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _patologiaController = TextEditingController();
    _patologias = List.from(widget.student.patologias);
    _isActive = widget.student.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _patologiaController.dispose();
    super.dispose();
  }

  void _addPatologia() {
    final newPatologia = _patologiaController.text.trim();
    if (newPatologia.isNotEmpty && !_patologias.contains(newPatologia)) {
      setState(() {
        _patologias.add(newPatologia);
        _patologiaController.clear();
      });
    }
  }

  void _removePatologia(String patologia) {
    setState(() => _patologias.remove(patologia));
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'patologias': _patologias,
        'is_active': _isActive,
      }).eq('id', widget.student.id).select('id, full_name, patologias, is_active');

      if (result.isEmpty) {
        throw Exception('No se actualizó ningún registro. Verificá las políticas RLS en Supabase.');
      }

      if (mounted) {
        context.read<AlumnosBloc>().add(AlumnosLoadRequested());
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alumno actualizado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar alumno: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Editar Alumno',
                    style: KaliText.headingItalic(KaliColors.espresso, size: 24),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: KaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nombre
              const _FieldLabel('Nombre Completo'),
              const SizedBox(height: 6),
              _buildTextField(_nameController, hint: 'Ej. María Pérez'),
              const SizedBox(height: 16),

              // Email (solo lectura — está en auth.users, no en profiles)
              const _FieldLabel('Correo Electrónico'),
              const SizedBox(height: 6),
              _buildTextField(_emailController, hint: 'correo@ejemplo.com', readOnly: true),
              const SizedBox(height: 16),

              // Estado activo
              const _FieldLabel('Estado'),
              const SizedBox(height: 6),
              _ActiveToggle(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 20),

              // Patologías
              const _FieldLabel('Patologías'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _patologiaController,
                      hint: 'Añadir patología...',
                      onSubmitted: (_) => _addPatologia(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addPatologia,
                    icon: const Icon(Icons.add_circle, color: KaliColors.clayDark, size: 30),
                  ),
                ],
              ),
              if (_patologias.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _patologias.map((p) => Chip(
                    label: Text(p, style: KaliText.body(KaliColors.espresso, size: 13)),
                    deleteIcon: const Icon(Icons.close, size: 15),
                    onDeleted: () => _removePatologia(p),
                    backgroundColor: KaliColors.sand,
                    side: BorderSide(color: KaliColors.clayDark.withValues(alpha: 0.3)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // Guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaliColors.clayDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Guardar Cambios', style: KaliText.body(Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String hint = '',
    bool readOnly = false,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onSubmitted: onSubmitted,
      style: KaliText.body(
        readOnly
            ? KaliColors.espresso.withValues(alpha: 0.45)
            : KaliColors.espresso,
        size: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: KaliText.body(KaliColors.espresso.withValues(alpha: 0.35), size: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KaliColors.espresso),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600, size: 13),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ActiveToggle({required this.value, required this.onChanged});

  static const _activeColor = Color(0xFF5C9E6C);
  static const _inactiveColor = Color(0xFFD4685C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (value ? _activeColor : _inactiveColor).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (value ? _activeColor : _inactiveColor).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 18,
              color: value ? _activeColor : _inactiveColor,
            ),
            const SizedBox(width: 8),
            Text(
              value ? 'Activo' : 'Inactivo',
              style: KaliText.body(
                value ? _activeColor : _inactiveColor,
                weight: FontWeight.w600,
                size: 14,
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _activeColor,
              inactiveThumbColor: _inactiveColor,
            ),
          ],
        ),
      ),
    );
  }
}
