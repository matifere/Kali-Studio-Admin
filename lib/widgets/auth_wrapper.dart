import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/screens/dashboard_screen.dart';
import 'package:argrity/screens/institution_selection_screen.dart';
import 'package:argrity/screens/inactive_screen.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_theme.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Si ProfileCache ya tiene datos (re-montaje en la misma sesión),
  // renderizamos sin ninguna espera. Si no, esperamos silenciosamente
  // (scaffold en blanco, imperceptible) hasta que _checkProfile() confirme.
  bool _profileChecked = ProfileCache.isLoaded;
  bool _hasInstitution = ProfileCache.institutionId != null;
  bool _isActive = false;
  /// true una vez que _checkProfile() completó la verificación de suscripción.
  /// Mientras sea false, el stream listener NO puede sobreescribir _isActive
  /// para evitar la race condition que causa bypass del paywall.
  bool _subscriptionChecked = false;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _checkProfile().then((_) {
      // Recién después de verificar la suscripción habilitamos el listener.
      _listenProfileChanges();
    });
  }

  void _listenProfileChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _profileSub = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) async {
          if (data.isNotEmpty && mounted && _subscriptionChecked) {
            final profile = data.first;
            final profileIsActive = profile['is_active'] as bool? ?? true;

            // Re-verificar la validez de la suscripción antes de decidir
            // si el usuario puede acceder al dashboard.
            final shouldBeActive = profileIsActive && await _isSubscriptionValid();

            if (mounted && shouldBeActive != _isActive) {
              setState(() => _isActive = shouldBeActive);
            }
          }
        });
  }

  /// Verifica si la suscripción de la institución es válida.
  /// Retorna true solo para estados explícitamente activos.
  Future<bool> _isSubscriptionValid() async {
    final isSudo = ProfileCache.role == 'sudo';
    final institutionId = ProfileCache.institutionId;
    if (!isSudo || institutionId == null) return true;

    try {
      final subData = await Supabase.instance.client
          .from('tenant_subscriptions')
          .select('status, current_period_end')
          .eq('institution_id', institutionId)
          .maybeSingle();

      if (subData == null) return false;

      final status = subData['status'] as String?;
      if (status == 'active' || status == 'authorized' || status == 'pending') {
        return true;
      } else if (status == 'cancelled' && subData['current_period_end'] != null) {
        final end = DateTime.tryParse(subData['current_period_end'].toString());
        return end != null && DateTime.now().isBefore(end);
      }
      return false;
    } catch (_) {
      // Fail-closed: ante cualquier error, denegar acceso
      return false;
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Sin sesión: no tocar el estado para no mostrar InstitutionSelectionScreen.
        // _KaliAppViewState manejará la navegación a LoginScreen.
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, institution_id, full_name, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        ProfileCache.set(
          role: data['role'] as String? ?? 'sudo',
          institutionId: data['institution_id'] as String?,
          fullName: data['full_name'] as String?,
        );
      }

      final isSubValid = await _isSubscriptionValid();

      if (mounted) {
        setState(() {
          _isActive = data != null
              ? ((data['is_active'] as bool? ?? true) && isSubValid)
              : false;
          _hasInstitution = data != null && data['institution_id'] != null;
          _profileChecked = true;
          _subscriptionChecked = true;
        });
      }
    } catch (_) {
      // Fail-closed: ante cualquier error, marcar como inactivo.
      if (mounted) {
        setState(() {
          _profileChecked = true;
          _subscriptionChecked = true;
          _isActive = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hasta que el perfil esté confirmado mostramos un scaffold en blanco —
    // sin spinner, invisible para el usuario (~100-200ms).
    if (!_profileChecked) {
      return const Scaffold(backgroundColor: KaliColors.warmWhite);
    }

    if (!_hasInstitution) return const InstitutionSelectionScreen();
    if (!_isActive) return const InactiveScreen();
    return const DashboardScreen();
  }
}
