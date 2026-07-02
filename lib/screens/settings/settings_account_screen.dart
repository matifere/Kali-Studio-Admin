import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/kali_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class SettingsAccountScreen extends StatefulWidget {
  const SettingsAccountScreen({super.key});

  @override
  State<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends State<SettingsAccountScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSavingName = false;
  bool _isSavingPassword = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = ProfileCache.fullName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == ProfileCache.fullName) return;

    setState(() => _isSavingName = true);
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(fullName: newName));
  }

  Future<void> _savePassword() async {
    final newPassword = _passwordController.text;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar contraseña: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email ?? 'correo@ejemplo.com';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileUpdated) {
          setState(() => _isSavingName = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
        } else if (state is AuthFailure) {
          setState(() => _isSavingName = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 20 : 40,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText('Cuenta',
                      style: kaliColors
                          .heading(kaliColors.espresso, size: isSmall ? 36 : 46)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1),
                  const SizedBox(height: 4),
                  Text(
                    'Gestioná tu información personal y de seguridad.',
                    style: kaliColors.body(
                      kaliColors.espresso.withValues(alpha: 0.6),
                      size: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sección de Perfil
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kaliColors.warmWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kaliColors.espresso.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText('Información Pública',
                            style: kaliColors.heading(kaliColors.espresso,
                                size: 20),
                            maxLines: 1),
                        const SizedBox(height: 24),
                        KaliTextField(
                          controller: _nameController,
                          label: 'Nombre de la institución o usuario',
                          hint: 'Ej. Kali Studio',
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSavingName ? null : _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kaliColors.espresso,
                              foregroundColor: kaliColors.warmWhite,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSavingName
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kaliColors.warmWhite),
                                  )
                                : const Text('Guardar Nombre'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección de Seguridad
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kaliColors.warmWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kaliColors.espresso.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText('Seguridad de la Cuenta',
                            style: kaliColors.heading(kaliColors.espresso,
                                size: 20),
                            maxLines: 1),
                        const SizedBox(height: 24),
                        KaliTextField(
                          controller: TextEditingController(text: email),
                          label: 'Correo electrónico',
                          hint: '',
                          readOnly:
                              true, // El correo no se puede cambiar directamente
                        ),
                        const SizedBox(height: 16),
                        KaliTextField(
                          controller: _passwordController,
                          label: 'Nueva contraseña',
                          hint: 'Mínimo 6 caracteres',
                          obscureText: _obscurePassword,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSavingPassword ? null : _savePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kaliColors.espresso,
                              foregroundColor: kaliColors.warmWhite,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSavingPassword
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kaliColors.warmWhite),
                                  )
                                : const Text('Actualizar Contraseña'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Cerrar sesión
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFFD4685C)),
                      label: Text(
                        'Cerrar sesión',
                        style: kaliColors.body(const Color(0xFFD4685C),
                            weight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
