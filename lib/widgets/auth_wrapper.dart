import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kali_studio/screens/dashboard_screen.dart';
import 'package:kali_studio/screens/institution_selection_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _checkProfile();
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
          .select('role, institution_id')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        ProfileCache.set(
          role: data['role'] as String? ?? 'sudo',
          institutionId: data['institution_id'] as String?,
        );
      }

      if (mounted) {
        setState(() {
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

    return _hasInstitution
        ? const DashboardScreen()
        : const InstitutionSelectionScreen();
  }
}
