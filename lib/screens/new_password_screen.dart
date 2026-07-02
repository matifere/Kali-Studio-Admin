import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/kali_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      _showSnack('Completá ambos campos.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (!mounted) return;
      _showSnack('¡Contraseña actualizada! Ya podés iniciar sesión.');
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al actualizar. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    const double widthInForm = 360;
    return Scaffold(
      backgroundColor: kaliColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 48,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kaliColors.espresso,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Icon(
                      Icons.lock_reset,
                      color: kaliColors.background,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nueva contraseña',
                  style: kaliColors.loginDisplay(kaliColors.espresso),
                ),
                Text(
                  'Elegí una contraseña segura para tu cuenta.',
                  style: kaliColors.loginBody(kaliColors.espresso),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsetsGeometry.all(40),
                child: SizedBox(
                  width: widthInForm,
                  child: Column(
                    spacing: 28,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KaliTextField(
                        label: 'NUEVA CONTRASEÑA',
                        hint: '••••••••',
                        suffixIcon:
                            _showPass ? Icons.visibility : Icons.visibility_off,
                        obscureText: !_showPass,
                        controller: _passCtrl,
                        onSuffixTap: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                      KaliTextField(
                        label: 'CONFIRMAR CONTRASEÑA',
                        hint: '••••••••',
                        suffixIcon: _showConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                        obscureText: !_showConfirm,
                        controller: _confirmCtrl,
                        onSuffixTap: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: kaliColors.warmWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('GUARDAR CONTRASEÑA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
