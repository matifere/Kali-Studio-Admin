import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:argrity/services/update_service.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class ForceUpdateScreen extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const ForceUpdateScreen({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    
    return Scaffold(
      backgroundColor: kaliColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icono y título ──────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: kaliColors.sand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  size: 40,
                  color: kaliColors.clayDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Actualización Requerida',
                style: kaliColors.loginDisplay(kaliColors.espresso),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Para continuar usando Argity, necesitás\nactualizar a la versión ${updateInfo.latestVersion}.',
                style: kaliColors.loginBody(kaliColors.clayDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // ── Tarjeta con detalles y botón ─────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Notas de la versión:',
                          style: kaliColors.label(kaliColors.espresso),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kaliColors.sand,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            updateInfo.releaseNotes,
                            style: kaliColors.body(kaliColors.clayDark).copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: kaliColors.clay,
                              foregroundColor: kaliColors.warmWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 22),
                            label: Text(
                              'DESCARGAR ACTUALIZACIÓN',
                              style: kaliColors.label(kaliColors.warmWhite).copyWith(
                                letterSpacing: 1.5,
                              ),
                            ),
                            onPressed: () async {
                              if (updateInfo.downloadUrl.isNotEmpty) {
                                final uri = Uri.parse(updateInfo.downloadUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
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
      ),
    );
  }
}

