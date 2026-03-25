import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardBottomPromos extends StatelessWidget {
  const DashboardBottomPromos({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Promo: Facility Health
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Image Placeholder
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ESTADO DE INSTALACIONES',
                          style: KaliText.label(KaliColors.espresso.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Optimización de Espacio',
                          style: KaliText.heading(KaliColors.espresso, size: 24).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El espacio de tu estudio se usa de manera más eficiente entre las 8 AM y 11 AM.',
                          style: KaliText.body(KaliColors.espresso.withOpacity(0.7), size: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Reporte Detallado',
                              style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 16, color: KaliColors.espresso),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right Promo: Need to hire
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: KaliColors.clayDark.withOpacity(0.8), // Using a dark clay color as in image
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Necesitas contratar?',
                        style: KaliText.heading(KaliColors.warmWhite, size: 28).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu proporción alumno-profesor es 18:1. Considerá agregar un nuevo profesor por la mañana.',
                        style: KaliText.body(KaliColors.warmWhite.withOpacity(0.9), size: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: KaliColors.espresso,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: Text(
                          'Abrir Bolsa de Trabajo',
                          style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Icon circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: KaliColors.warmWhite,
                      size: 32,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
