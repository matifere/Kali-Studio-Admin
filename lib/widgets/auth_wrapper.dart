import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kali_studio/screens/dashboard_screen.dart';
import 'package:kali_studio/screens/institution_selection_screen.dart';
import 'package:kali_studio/screens/inactive_screen.dart';
import 'package:kali_studio/services/profile_cache.dart';
import 'package:kali_studio/theme/kali_theme.dart';

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
  bool _isActive = true;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _checkProfile();
    _listenProfileChanges();
  }

  void _listenProfileChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _profileSub = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final profile = data.first;
            final currentIsActive = profile['is_active'] as bool? ?? true;
            if (currentIsActive != _isActive) {
              setState(() => _isActive = currentIsActive);
            }
          }
        });
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

      bool isSubValid = true;
      if (data != null && data['institution_id'] != null) {
        final subData = await Supabase.instance.client
            .from('tenant_subscriptions')
            .select('status, current_period_end')
            .eq('institution_id', data['institution_id'])
            .maybeSingle();
            
        if (subData != null && subData['status'] == 'cancelled' && subData['current_period_end'] != null) {
          final end = DateTime.tryParse(subData['current_period_end'].toString());
          if (end != null && DateTime.now().isAfter(end)) {
            isSubValid = false;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isActive = data != null ? ((data['is_active'] as bool? ?? true) && isSubValid) : true;
          _hasInstitution = data != null && data['institution_id'] != null;
          _profileChecked = true;
        });
      }
    } catch (_) {
      // En caso de error, marcamos como verificado para no quedar bloqueados.
      if (mounted) setState(() => _profileChecked = true);
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

