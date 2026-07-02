import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/pagos/saas_subscription_view.dart';

class SettingsSubscriptionScreen extends StatelessWidget {
  const SettingsSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
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
                Text(
                  'Suscripción',
                  style: kaliColors.heading(kaliColors.espresso, size: isSmall ? 36 : 46).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestioná tu plan y pagos de Argity.',
                  style: kaliColors.body(
                    kaliColors.espresso.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 32),
                const SaasSubscriptionView(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
