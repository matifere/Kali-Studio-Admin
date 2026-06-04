import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/bloc/notifications/notifications_cubit.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';


// ── Barra de navegación superior ──────────────────────────────────────────────
//
// Convertida a StatefulWidget para poder redibujar la sección del nombre
// luego de que el diálogo de edición de perfil cierra con éxito.
class DashboardTopNavBar extends StatefulWidget {
  const DashboardTopNavBar({super.key});

  @override
  State<DashboardTopNavBar> createState() => _DashboardTopNavBarState();
}

class _DashboardTopNavBarState extends State<DashboardTopNavBar> {
  // Rol leído del caché en memoria, sin round trip a la base de datos.
  final String _role = ProfileCache.role;

  // ── Logout ──────────────────────────────────────────────────────────────────
  void _handleLogout(BuildContext ctx) {
    ctx.read<AuthBloc>().add(AuthLogoutRequested());
  }

  // ── Editar Perfil ───────────────────────────────────────────────────────────
  void _openEditProfile(BuildContext ctx) async {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final success = await showDialog<bool>(
      context: ctx,
      builder: (_) => _EditProfileDialog(
        currentName: metadata['full_name'] as String? ?? '',
        currentEmail: user?.email ?? '',
      ),
    );
    if (success == true && ctx.mounted) {
      setState(() {});
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(
            'Perfil actualizado. Si cambiaste el correo, confirmá el cambio desde tu bandeja de entrada.',
          ),
          backgroundColor: KaliColors.espresso,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Solo reaccionar a transiciones reales — ignorar el estado
      // que ya existía cuando este widget se monta en otra pantalla.
      listenWhen: (previous, current) =>
          previous is! AuthInitial &&
          (current is AuthSuccess || current is AuthFailure),
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          ctx.read<AuthBloc>().add(AuthReset());
          // La navegación (ej. hacia LoginScreen al cerrar sesión)
          // es manejada de forma centralizada por main.dart.
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
        final displayRole = switch (_role.toLowerCase()) {
          'sudo'  => 'DUEÑO',
          'admin' => 'PROFESOR',
          _       => _role.toUpperCase(),
        };
        final avatarUrl = metadata['avatar_url'] as String?;
        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
        final bool isMobile = MediaQuery.of(ctx).size.width < 1100;
        final bool isUltraMobile = MediaQuery.of(ctx).size.width < 500;

        return Padding(
          padding: EdgeInsets.fromLTRB(
              isUltraMobile ? 20 : 40, 32, isUltraMobile ? 20 : 40, 0),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu, color: KaliColors.espresso),
                  onPressed: () {
                    Scaffold.of(ctx).openDrawer();
                  },
                ),
              // ── Logo + nombre en desktop ───────────────────────────────────
              if (!isMobile) ...[
                Image.asset(
                  'assets/images/argity_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'argity',
                  style: KaliText.heading(KaliColors.espresso, size: 20),
                ),
              ],
              const Spacer(),

              // ── Iconos ─────────────────────────────────────────────────────
              const _NotificationsButton(),
              const SizedBox(width: 16),

              // ── Perfil de Usuario (clickeable) ─────────────────────────────
              _UserProfileButton(
                fullName: fullName,
                displayRole: displayRole,
                initial: initial,
                avatarUrl: avatarUrl,
                isLoading: state is AuthLoading,
                onEditProfile: () => _openEditProfile(ctx),
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
      onEnter: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true); },
      onExit: (e) { if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false); },
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

// ── Diálogo de Edición de Perfil ──────────────────────────────────────────────
class _EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const _EditProfileDialog({
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'El correo no puede estar vacío');
      return;
    }
    if (password.isNotEmpty) {
      if (password.length < 6) {
        setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
        return;
      }
      if (password != confirm) {
        setState(() => _error = 'Las contraseñas no coinciden');
        return;
      }
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesión activa');

      final bool nameChanged = name != widget.currentName;
      final bool emailChanged = email != widget.currentEmail;
      final bool passwordChanged = password.isNotEmpty;

      // Build a single updateUser call with all changes
      await client.auth.updateUser(UserAttributes(
        email: emailChanged ? email : null,
        password: passwordChanged ? password : null,
        data: nameChanged ? {'full_name': name} : null,
      ));

      // Keep profiles table in sync for the name
      if (nameChanged) {
        await client
            .from('profiles')
            .update({'full_name': name})
            .eq('id', userId);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'No se pudo guardar: $e'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: KaliColors.warmWhite,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Editar Perfil',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: KaliColors.espresso,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: KaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Información personal ──────────────────────────────
              const _SectionLabel('INFORMACIÓN PERSONAL'),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Nombre completo',
                controller: _nameController,
                hint: 'Tu nombre completo',
              ),
              const SizedBox(height: 28),

              // ── Sección: Cuenta ────────────────────────────────────────────
              const _SectionLabel('CUENTA'),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Correo electrónico',
                controller: _emailController,
                hint: 'correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: Color(0xFF8A7C6E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Si cambiás el correo, recibirás un link de confirmación en la nueva dirección.',
                      style: KaliText.caption(
                          KaliColors.espresso.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProfileField(
                label: 'Nueva contraseña',
                controller: _passwordController,
                hint: 'Dejar vacío para no cambiarla',
                obscureText: !_showPassword,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: KaliColors.espresso.withValues(alpha: 0.45),
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Confirmar contraseña',
                controller: _confirmController,
                hint: 'Repetí la nueva contraseña',
                obscureText: !_showConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: KaliColors.espresso.withValues(alpha: 0.45),
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),

              // ── Error ──────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: KaliText.body(const Color(0xFFD4685C), size: 13),
                ),
              ],

              const SizedBox(height: 32),

              // ── Botones ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MouseRegion(
                    cursor: _isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? KaliColors.espresso.withValues(alpha: 0.6)
                              : KaliColors.espresso,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: KaliColors.warmWhite,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Guardar cambios',
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
      ),
    );
  }
}

// ── Helpers internos del diálogo ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.4)),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600, size: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: KaliText.body(KaliColors.espresso, size: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KaliText.body(KaliColors.espresso.withValues(alpha: 0.35), size: 14),
            suffixIcon: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KaliColors.espresso),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Botón de Notificaciones con menú ──────────────────────────────────────────
class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = state.unreadCount;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications,
                  color: KaliColors.espresso.withValues(alpha: 0.6)),
              onPressed: () {
                _showNotificationsMenu(context, state.notifications);
                context.read<NotificationsCubit>().markAllAsRead();
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4685C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: KaliColors.warmWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsMenu(BuildContext context, List<NotificationItem> notifications) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 250,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: KaliColors.warmWhite,
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notificaciones',
                style: KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(color: KaliColors.sand2, height: 1),
            ],
          ),
        ),
        if (notifications.isEmpty)
          PopupMenuItem(
            enabled: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No hay notificaciones',
                    style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5))),
              ),
            ),
          )
        else
          ...notifications.map((n) => PopupMenuItem(
                value: n.id,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600, size: 14)),
                    const SizedBox(height: 4),
                    Text(n.message, style: KaliText.body(KaliColors.espresso, size: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                      style: KaliText.caption(KaliColors.espresso.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
