import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:kali_studio/bloc/auth/auth_bloc.dart';
import 'package:kali_studio/screens/login_screen.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';

// ── Barra de navegación superior ──────────────────────────────────────────────
//
// Convertida a StatefulWidget para poder redibujar la sección del nombre
// luego de una actualización de perfil exitosa (AuthProfileUpdated).
class DashboardTopNavBar extends StatefulWidget {
  const DashboardTopNavBar({super.key});

  @override
  State<DashboardTopNavBar> createState() => _DashboardTopNavBarState();
}

class _DashboardTopNavBarState extends State<DashboardTopNavBar> {
  // ── Logout ──────────────────────────────────────────────────────────────────
  void _handleLogout(BuildContext ctx) {
    ctx.read<AuthBloc>().add(AuthLogoutRequested());
  }

  // ── Editar Perfil ───────────────────────────────────────────────────────────
  void _openEditProfile(BuildContext ctx, String currentName) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => BlocProvider.value(
        value: ctx.read<AuthBloc>(),
        child: _EditProfileDialog(currentName: currentName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Solo reaccionar a transiciones reales — ignorar el estado
      // que ya existía cuando este widget se monta en otra pantalla.
      listenWhen: (previous, current) =>
          previous is! AuthInitial &&
          (current is AuthSuccess ||
          current is AuthProfileUpdated ||
          current is AuthFailure),
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          // Logout exitoso → volver al login limpiando el stack
          ctx.read<AuthBloc>().add(AuthReset());
          Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else if (state is AuthProfileUpdated) {
          ctx.read<AuthBloc>().add(AuthReset());
          // Refrescar la UI para mostrar el nuevo nombre
          setState(() {});
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Perfil actualizado correctamente'),
              backgroundColor: KaliColors.espresso,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFD4685C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          ctx.read<AuthBloc>().add(AuthReset());
        }
      },
      builder: (ctx, state) {
        final user = Supabase.instance.client.auth.currentUser;
        final metadata = user?.userMetadata ?? {};
        final fullName = metadata['full_name'] as String? ?? 'Usuario Admin';
        final rawRole = metadata['role'] as String? ?? 'admin';
        final displayRole = rawRole.toUpperCase() == 'ADMIN'
            ? 'GESTOR DEL ESTUDIO'
            : rawRole.toUpperCase();
        final avatarUrl = metadata['avatar_url'] as String?;
        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: Row(
            children: [
              const Spacer(),

              // ── Iconos ─────────────────────────────────────────────────────
              IconButton(
                icon: Icon(Icons.notifications,
                    color: KaliColors.espresso.withValues(alpha: 0.6)),
                onPressed: () {},
              ),
              const SizedBox(width: 16),

              // ── Perfil de Usuario (clickeable) ─────────────────────────────
              _UserProfileButton(
                fullName: fullName,
                displayRole: displayRole,
                initial: initial,
                avatarUrl: avatarUrl,
                isLoading: state is AuthLoading,
                onEditProfile: () => _openEditProfile(ctx, fullName),
                onLogout: () => _handleLogout(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Botón del perfil de usuario con menú ──────────────────────────────────────
class _UserProfileButton extends StatefulWidget {
  final String fullName;
  final String displayRole;
  final String initial;
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const _UserProfileButton({
    required this.fullName,
    required this.displayRole,
    required this.initial,
    required this.avatarUrl,
    required this.isLoading,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  State<_UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<_UserProfileButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
              Divider(color: KaliColors.sand2, height: 1),
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

// ── Diálogo de Edición de Perfil ──────────────────────────────────────────────
class _EditProfileDialog extends StatefulWidget {
  final String currentName;

  const _EditProfileDialog({required this.currentName});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(fullName: name));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: KaliColors.warmWhite,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Editar Perfil',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: KaliColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los cambios se reflejarán inmediatamente.',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            // Campo de nombre
            KaliTextField(
              controller: _nameController,
              label: 'Nombre completo',
              hint: 'Tu nombre',
            ),
            const SizedBox(height: 40),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: KaliText.body(
                        KaliColors.espresso.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: KaliColors.espresso,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Guardar',
                        style: KaliText.body(KaliColors.warmWhite,
                            weight: FontWeight.w600, size: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
