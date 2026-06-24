import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:argrity/bloc/auth/auth_bloc.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/dashboard/edit_profile_dialog.dart';
import 'package:argrity/widgets/dashboard/user_profile_button.dart';

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
      builder: (_) => EditProfileDialog(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          'sudo' => 'DUEÑO',
          'admin' => 'PROFESOR',
          _ => _role.toUpperCase(),
        };
        final avatarUrl = metadata['avatar_url'] as String?;
        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
        final bool isMobile = MediaQuery.of(ctx).size.width < 1100;
        final bool isUltraMobile = MediaQuery.of(ctx).size.width < 500;

        return Padding(
          padding: EdgeInsets.fromLTRB(isUltraMobile ? 20 : 40,
              isMobile ? 12 : 32, isUltraMobile ? 20 : 40, 0),
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

              // TODO: Descomentar cuando las notificaciones estén funcionales
              // const NotificationsButton(),
              // const SizedBox(width: 16),

              // ── Perfil de Usuario (clickeable) ─────────────────────────────
              UserProfileButton(
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
