import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:argrity/theme/kali_theme.dart';

class UserProfileButton extends StatefulWidget {
  final String fullName;
  final String displayRole;
  final String initial;
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const UserProfileButton({
    super.key,
    required this.fullName,
    required this.displayRole,
    required this.initial,
    required this.avatarUrl,
    required this.isLoading,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  State<UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<UserProfileButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTapDown: (details) => _showUserMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.sand : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (MediaQuery.of(context).size.width > 600)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.fullName,
                      style: KaliText.body(KaliColors.espresso,
                          weight: FontWeight.bold),
                    ),
                    Text(
                      widget.displayRole,
                      style: KaliText.label(
                          KaliColors.espresso.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              if (MediaQuery.of(context).size.width > 600)
                const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: KaliColors.clay,
                    backgroundImage: widget.avatarUrl != null
                        ? NetworkImage(widget.avatarUrl!)
                        : null,
                    child: widget.avatarUrl == null
                        ? Text(
                            widget.initial,
                            style: KaliText.body(KaliColors.warmWhite,
                                weight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (widget.isLoading)
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KaliColors.espresso,
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

  void _showUserMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 160,
        position.dy + 8,
        position.dx,
        position.dy,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: KaliColors.warmWhite,
      items: [
        // Cabecera decorativa del menú
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fullName,
                style:
                    KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
              ),
              Text(
                widget.displayRole,
                style: KaliText.caption(
                    KaliColors.espresso.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 8),
              const Divider(color: KaliColors.sand2, height: 1),
            ],
          ),
        ),
        // Editar perfil
        PopupMenuItem(
          value: 'edit',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 16, color: KaliColors.espresso.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Text('Editar perfil',
                  style: KaliText.body(KaliColors.espresso, size: 14)),
            ],
          ),
        ),
        // Cerrar sesión
        PopupMenuItem(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 16, color: Color(0xFFD4685C)),
              const SizedBox(width: 10),
              Text('Cerrar sesión',
                  style: KaliText.body(const Color(0xFFD4685C), size: 14)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') widget.onEditProfile();
      if (value == 'logout') widget.onLogout();
    });
  }
}
