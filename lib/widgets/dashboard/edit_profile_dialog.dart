import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'El correo no puede estar vacío');
      return;
    }
    if (password.isNotEmpty) {
      if (password.length < 6) {
        setState(
            () => _error = 'La contraseña debe tener al menos 6 caracteres');
        return;
      }
      if (password != confirm) {
        setState(() => _error = 'Las contraseñas no coinciden');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesión activa');

      final bool nameChanged = name != widget.currentName;
      final bool emailChanged = email != widget.currentEmail;
      final bool passwordChanged = password.isNotEmpty;

      // Build a single updateUser call with all changes
      await client.auth.updateUser(UserAttributes(
        email: emailChanged ? email : null,
        password: passwordChanged ? password : null,
        data: nameChanged ? {'full_name': name} : null,
      ));

      // Keep profiles table in sync for the name
      if (nameChanged) {
        await client
            .from('profiles')
            .update({'full_name': name}).eq('id', userId);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo guardar: $e';
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Editar Perfil',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: kaliColors.espresso,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: kaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Información personal ──────────────────────────────
              const _SectionLabel('INFORMACIÓN PERSONAL'),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Nombre completo',
                controller: _nameController,
                hint: 'Tu nombre completo',
              ),
              const SizedBox(height: 28),

              // ── Sección: Cuenta ────────────────────────────────────────────
              const _SectionLabel('CUENTA'),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Correo electrónico',
                controller: _emailController,
                hint: 'correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: Color(0xFF8A7C6E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Si cambiás el correo, recibirás un link de confirmación en la nueva dirección.',
                      style: KaliText.caption(
                          kaliColors.espresso.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProfileField(
                label: 'Nueva contraseña',
                controller: _passwordController,
                hint: 'Dejar vacío para no cambiarla',
                obscureText: !_showPassword,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: kaliColors.espresso.withValues(alpha: 0.45),
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Confirmar contraseña',
                controller: _confirmController,
                hint: 'Repetí la nueva contraseña',
                obscureText: !_showConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: kaliColors.espresso.withValues(alpha: 0.45),
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),

              // ── Error ──────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: KaliText.body(const Color(0xFFD4685C), size: 13),
                ),
              ],

              const SizedBox(height: 32),

              // ── Botones ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: KaliText.body(
                          kaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MouseRegion(
                    cursor: _isLoading
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
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
                                'Guardar cambios',
                                style: KaliText.body(kaliColors.warmWhite,
                                    weight: FontWeight.w600, size: 13),
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
    );
  }
}

// ── Helpers internos del diálogo ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Text(
      text,
      style: KaliText.label(kaliColors.espresso.withValues(alpha: 0.4)),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KaliText.body(kaliColors.espresso,
              weight: FontWeight.w600, size: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: KaliText.body(kaliColors.espresso, size: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KaliText.body(
                kaliColors.espresso.withValues(alpha: 0.35),
                size: 14),
            suffixIcon: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: kaliColors.espresso.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kaliColors.espresso),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
