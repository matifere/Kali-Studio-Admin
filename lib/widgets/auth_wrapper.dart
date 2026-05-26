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
  bool _isLoading = true;
  bool _hasInstitution = false;
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

            // If the active state changes, update the UI immediately
            if (currentIsActive != _isActive) {
              setState(() {
                _isActive = currentIsActive;
              });
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch role + institution en una sola query y pobla el caché global.
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

      if (mounted) {
        setState(() {
          _isActive =
              data != null ? (data['is_active'] as bool? ?? true) : true;
          _hasInstitution = data != null && data['institution_id'] != null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: KaliColors.warmWhite,
        body: Center(
          child: CircularProgressIndicator(color: KaliColors.espresso),
        ),
      );
    }

    if (!_hasInstitution) {
      return const InstitutionSelectionScreen();
    }

    if (!_isActive) {
      return const InactiveScreen();
    }

    return const DashboardScreen();
  }
}
