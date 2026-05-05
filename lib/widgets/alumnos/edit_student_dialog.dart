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
  late TextEditingController _patologiaController;
  late List<String> _patologias;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _patologiaController = TextEditingController();
    _patologias = List.from(widget.student.patologias);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    setState(() {
      _patologias.remove(patologia);
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text,
        'patologias': _patologias,
      }).eq('id', widget.student.id);

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
          SnackBar(content: Text('Error al actualizar alumno: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Patologías',
              style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patologiaController,
                    decoration: InputDecoration(
                      hintText: 'Añadir patología...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addPatologia(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addPatologia,
                  icon: const Icon(Icons.add_circle, color: KaliColors.clayDark, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patologias.map((p) => Chip(
                label: Text(p),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removePatologia(p),
                backgroundColor: KaliColors.sand,
                side: BorderSide(color: KaliColors.clayDark.withValues(alpha: 0.3)),
              )).toList(),
            ),
            const SizedBox(height: 32),
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
    );
  }
}
