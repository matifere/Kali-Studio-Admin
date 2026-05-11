import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kali_studio/screens/dashboard_screen.dart';
import 'package:kali_studio/screens/institution_selection_screen.dart';
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
    _checkInstitution();
  }

  Future<void> _checkInstitution() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }
      final data = await Supabase.instance.client
          .from('profiles')
          .select('institution_id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _hasInstitution = data != null && data['institution_id'] != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    if (_hasInstitution) {
      return const DashboardScreen();
    } else {
      return const InstitutionSelectionScreen();
    }
  }
}
