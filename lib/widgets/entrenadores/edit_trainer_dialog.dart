import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/kali_text_field.dart';

/// Diálogo para editar un entrenador (nombre, email y/o contraseña).
///
/// El email y la contraseña viven en `auth.users`, así que se actualizan a
/// través de la Edge Function `update-trainer` (que usa la service_role key
/// del lado servidor). El nombre se sincroniza en `profiles` en la misma
/// función. Devuelve el mapa del entrenador actualizado al hacer pop.
class EditTrainerDialog extends StatefulWidget {
  final Map<String, dynamic> trainer;

  const EditTrainerDialog({super.key, required this.trainer});

  @override
  State<EditTrainerDialog> createState() => _EditTrainerDialogState();
}

class _EditTrainerDialogState extends State<EditTrainerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  late final String _initialName;
  late final String _initialEmail;

  @override
  void initState() {
    super.initState();
    _initialName = (widget.trainer['full_name'] as String? ?? '').trim();
    _initialEmail = (widget.trainer['email'] as String? ?? '').trim();
    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty) {
      setState(() => _error = 'El nombre y el email no pueden estar vacíos');
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    // Solo enviamos los campos que realmente cambiaron.
    final payload = <String, dynamic>{'trainer_id': widget.trainer['id']};
    if (name != _initialName) payload['full_name'] = name;
    if (email != _initialEmail.toLowerCase()) payload['email'] = email;
    if (password.isNotEmpty) payload['password'] = password;

    if (payload.length == 1) {
      setState(() => _error = 'No hay cambios para guardar');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'update-trainer',
        body: payload,
      );

      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }

      // La función devuelve el perfil actualizado; si no, componemos el mapa
      // localmente con los valores enviados para refrescar la UI igual.
      final updated = <String, dynamic>{
        ...widget.trainer,
        if (name != _initialName) 'full_name': name,
        if (email != _initialEmail.toLowerCase()) 'email': email,
      };
      if (data is Map && data['trainer'] is Map) {
        updated.addAll(Map<String, dynamic>.from(data['trainer'] as Map));
      }

      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _friendlyError(e);
        });
      }
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (raw.toLowerCase().contains('already') ||
        raw.toLowerCase().contains('use') ||
        raw.contains('registered')) {
      return 'Ese email ya está en uso por otra cuenta.';
    }
    return raw.isEmpty ? 'No se pudo guardar. Intentá nuevamente.' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kaliColors.warmWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Editar Entrenador',
                        style: kaliColors
                            .heading(kaliColors.espresso, size: 30)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: kaliColors.espresso),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Actualizá el nombre, el email o la contraseña de acceso.',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 28),

                KaliTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  hint: 'Ej. Valentina López',
                ),
                const SizedBox(height: 16),
                KaliTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  hint: 'correo@ejemplo.com',
                ),
                const SizedBox(height: 16),
                KaliTextField(
                  controller: _passwordController,
                  label: 'Nueva contraseña (opcional)',
                  hint: 'Dejar vacío para no cambiarla',
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style:
                          kaliColors.body(const Color(0xFFD4685C), size: 13)),
                ],

                const SizedBox(height: 28),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: kaliColors
                            .body(kaliColors.espresso.withValues(alpha: 0.6)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    MouseRegion(
                      cursor: _isLoading
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? kaliColors.espresso.withValues(alpha: 0.6)
                                : kaliColors.espresso,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: kaliColors.warmWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Guardar Cambios',
                                  style: kaliColors.body(
                                    kaliColors.warmWhite,
                                    weight: FontWeight.w600,
                                    size: 13,
                                  ),
                                ),
                        ),
                      ),
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
