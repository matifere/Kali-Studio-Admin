import 'package:flutter/material.dart';
import 'package:argrity/services/auth_service.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/kali_text_field.dart';

class CreateTrainerDialog extends StatefulWidget {
  const CreateTrainerDialog({super.key});

  @override
  State<CreateTrainerDialog> createState() => _CreateTrainerDialogState();
}

class _CreateTrainerDialogState extends State<CreateTrainerDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await SupaAuthClass().registrarEntrenador(email, password, name);

    if (result.startsWith('Ok:')) {
      final newId = result.substring(3);
      if (mounted) {
        Navigator.of(context).pop({
          'id': newId,
          'full_name': name,
          'email': email,
          'role': 'admin',
          'is_active': true,
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = result;
        });
      }
    }
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
                      'Añadir Entrenador',
                      style: kaliColors.heading(kaliColors.espresso, size: 30).copyWith(fontWeight: FontWeight.w600),
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
                'Se registrará con acceso de entrenador (rol admin).',
                style:
                    kaliColors.body(kaliColors.espresso.withValues(alpha: 0.6)),
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
                label: 'Contraseña temporal',
                hint: 'Mínimo 6 caracteres',
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
                    style: kaliColors.body(const Color(0xFFD4685C), size: 13)),
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
                                'Registrar Entrenador',
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
        )),
      ),
    );
  }
}
