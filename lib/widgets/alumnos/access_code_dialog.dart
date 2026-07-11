import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:argrity/models/student.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diálogo para ver/generar el código de acceso de un alumno.
///
/// El código permite al alumno iniciar sesión en la app cliente sin email ni
/// contraseña (la Edge Function `login-with-code` lo valida y la institución
/// sale de su perfil). Hay un solo código activo por alumno: regenerar revoca
/// el anterior.
class AccessCodeDialog extends StatefulWidget {
  final Student student;
  const AccessCodeDialog({super.key, required this.student});

  @override
  State<AccessCodeDialog> createState() => _AccessCodeDialogState();
}

class _AccessCodeDialogState extends State<AccessCodeDialog> {
  bool _loading = true;
  bool _generating = false;
  String? _code;
  DateTime? _lastUsedAt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentCode();
  }

  Future<void> _loadCurrentCode() async {
    try {
      final row = await Supabase.instance.client
          .from('access_codes')
          .select('code, last_used_at')
          .eq('user_id', widget.student.id)
          .isFilter('revoked_at', null)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _code = row?['code'] as String?;
        _lastUsedAt = row?['last_used_at'] != null
            ? DateTime.tryParse(row!['last_used_at'] as String)?.toLocal()
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'No se pudo cargar el código. Intentá nuevamente.';
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _errorMessage = null;
    });

    try {
      final code = await Supabase.instance.client.rpc(
        'generate_access_code',
        params: {'p_student_id': widget.student.id},
      ) as String?;

      if (!mounted) return;
      setState(() {
        _code = code;
        _lastUsedAt = null;
        _generating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _errorMessage = 'No se pudo generar el código. Intentá nuevamente.';
      });
    }
  }

  /// ABCD1234 → ABCD-1234, más fácil de dictar y tipear.
  String get _formattedCode {
    final c = _code!;
    if (c.length != 8) return c;
    return '${c.substring(0, 4)}-${c.substring(4)}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _formattedCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kaliColors.warmWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Código de acceso',
                      style: kaliColors.headingItalic(kaliColors.espresso,
                          size: 24),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: kaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.student.name} puede iniciar sesión en la app solo '
                'con este código, sin email ni contraseña. Al regenerarlo, el '
                'código anterior deja de funcionar.',
                style:
                    kaliColors.body(kaliColors.espresso.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_code != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: kaliColors.sand,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kaliColors.espresso.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _formattedCode,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: kaliColors.espresso,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar',
                        onPressed: _copy,
                        icon: Icon(Icons.copy_rounded,
                            color: kaliColors.clayDark),
                      ),
                    ],
                  ),
                ),
                if (_lastUsedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Usado por última vez el '
                    '${_lastUsedAt!.day}/${_lastUsedAt!.month}/${_lastUsedAt!.year}',
                    style: kaliColors.body(
                        kaliColors.espresso.withValues(alpha: 0.5),
                        size: 12),
                  ),
                ],
              ] else
                Text(
                  'Este alumno todavía no tiene un código de acceso.',
                  style: kaliColors
                      .body(kaliColors.espresso.withValues(alpha: 0.7)),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: kaliColors.body(const Color(0xFFD4685C), size: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_loading || _generating) ? null : _generate,
                  style: FilledButton.styleFrom(
                    backgroundColor: kaliColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _generating
                        ? 'Generando...'
                        : (_code == null
                            ? 'Generar código'
                            : 'Regenerar código'),
                    style: kaliColors.body(kaliColors.warmWhite,
                        weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
