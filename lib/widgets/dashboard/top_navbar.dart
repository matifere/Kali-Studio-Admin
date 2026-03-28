import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class DashboardTopNavBar extends StatelessWidget {
  const DashboardTopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: KaliColors.sand,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: KaliColors.espresso.withValues(alpha: 0.4)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: KaliText.body(KaliColors.espresso),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Buscar alumnos, pagos...',
                        hintStyle: KaliText.body(KaliColors.espresso.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Icons
          IconButton(
            icon: Icon(Icons.notifications, color: KaliColors.espresso.withValues(alpha: 0.6)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings, color: KaliColors.espresso.withValues(alpha: 0.6)),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          // User Profile
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Usuario Admin',
                    style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
                  ),
                  Text(
                    'GESTOR DEL ESTUDIO',
                    style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: KaliColors.clay,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              )
            ],
          )
        ],
      ),
    );
  }
}
