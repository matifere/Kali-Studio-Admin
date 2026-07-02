import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/entrenadores/entrenadores_table.dart';

class EntrenadoresScreen extends StatelessWidget {
  const EntrenadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrenadores',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isSmall ? 36 : 46,
                    fontWeight: FontWeight.w600,
                    color: kaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestioná el equipo de entrenadores.',
                  style: KaliText.body(
                    kaliColors.espresso.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 32),
                const EntrenadoresTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

