import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:argrity/utils/oauth_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Future<void> _handleMercadoPagoRegister(BuildContext context) async {
    const String clientId = '5257839397807870';
    const String redirectUri = 'https://dbturnos.argity.com/functions/v1/mp-auth-callback';
    
    if (kIsWeb) {
      // Pasamos la URL pero evitando que empiece con http:// o https:// porque el WAF de MP lo bloquea
      String appRedirect = Uri.base.origin;
      String encodedState = base64Url.encode(utf8.encode(appRedirect));
      final Uri url = Uri.https(
        'auth.mercadopago.com',
        '/authorization',
        {
          'client_id': clientId,
          'response_type': 'code',
          'platform_id': 'mp',
          'redirect_uri': redirectUri,
          'state': 'b64:$encodedState',
        },
      );
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Mercado Pago')));
        }
      }
    } else {
      // Para Escritorio (Win/Mac/Lin) o Móvil usamos un servidor web efímero
      try {
        await handleDesktopOAuth(clientId, redirectUri);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
        }
      }
    }
  }

  // ── Panel decorativo izquierdo (solo escritorio) ──────────────────────────
  Widget _buildBrandPanel(KaliColorsExtension kaliColors) {
    return Container(
      color: kaliColors.espresso,
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            "Crear Perfil\nAdministrativo",
            style: kaliColors.display(kaliColors.warmWhite).copyWith(
                  fontSize: 48,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            "Comienza a gestionar tu institución\nhoy con herramientas diseñadas\npara la administración profesional.",
            style: kaliColors.body(
              kaliColors.clay,
              size: 16,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Formulario de registro ────────────────────────────────────────────────
  Widget _buildForm(
      BuildContext context, bool isLoading, KaliColorsExtension kaliColors) {
    return Container(
      color: kaliColors.warmWhite,
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Registro de Staff",
              style: kaliColors.heading(
                kaliColors.espresso,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Únete utilizando tu cuenta de Mercado Pago para configurar el acceso administrativo al portal del estudio.",
              style: kaliColors.body(
                kaliColors.clayDark,
                size: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Esta sección está destinada exclusivamente a los administradores. Si sos un entrenador, debes iniciar sesión con las credenciales provistas por un administrador.",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _handleMercadoPagoRegister(context),
                icon: isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.account_balance_wallet, size: 24), // Ícono representativo de billetera
                label: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: kaliColors.warmWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "REGISTRARSE CON MERCADO PAGO",
                        style: kaliColors.label(kaliColors.warmWhite).copyWith(
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009EE3), // Azul oficial de Mercado Pago
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: RichText(
                  text: TextSpan(
                    style: kaliColors.body(
                      kaliColors.clayDark,
                      size: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: "¿Ya eres parte del equipo? ",
                      ),
                      TextSpan(
                        text: "Iniciar Sesión",
                        style: TextStyle(
                          color: kaliColors.espresso,
                          fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthSuccess ||
          current is AuthFailure ||
          current is AuthPending,
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.read<AuthBloc>().add(AuthReset());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso')),
          );
          // La navegación a AuthWrapper es manejada por onAuthStateChange en main.dart
        } else if (state is AuthPending) {
          context.read<AuthBloc>().add(AuthReset());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada.'),
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop();
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        // En pantallas anchas mostramos el panel decorativo + formulario lado a
        // lado; en celular, una sola columna con el formulario a ancho completo.
        final bool isWide = MediaQuery.of(context).size.width >= 800;
        return Scaffold(
          backgroundColor: kaliColors.background,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : 460,
                    maxHeight: isWide ? 600 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: kaliColors.warmWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                flex: 4, child: _buildBrandPanel(kaliColors)),
                            Expanded(
                              flex: 6,
                              child: _buildForm(context, isLoading, kaliColors),
                            ),
                          ],
                        )
                      : _buildForm(context, isLoading, kaliColors),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
