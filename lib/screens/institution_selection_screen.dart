import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/kali_text_field.dart';
import 'package:argrity/widgets/auth_wrapper.dart';
import 'package:argrity/screens/login_screen.dart';
import 'package:argrity/services/profile_cache.dart';

class InstitutionSelectionScreen extends StatefulWidget {
  const InstitutionSelectionScreen({super.key});

  @override
  State<InstitutionSelectionScreen> createState() =>
      _InstitutionSelectionScreenState();
}

class _InstitutionSelectionScreenState
    extends State<InstitutionSelectionScreen> {
  final TextEditingController _createNameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _createNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _createNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa un nombre para la institución')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No session');

      final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

      // Usamos una función RPC para evitar el problema de RLS
      await Supabase.instance.client.rpc('create_institution', params: {
        'inst_name': name,
        'inst_slug': slug,
      });

      // Buscamos la institución recién creada
      final instRes = await Supabase.instance.client
          .from('institutions')
          .select('id')
          .eq('slug', slug)
          .single();

      final instId = instRes['id'];

      // Actualizamos el perfil del usuario actual para asignarlo a la institución
      await Supabase.instance.client.from('profiles').update({
        'institution_id': instId,
        'role': 'sudo',
      }).eq('id', user.id);

      // Refrescamos el caché para que AuthWrapper enrute con datos actualizados
      // y no vuelva a mostrar esta pantalla mientras re-verifica el perfil.
      ProfileCache.set(
        role: 'sudo',
        institutionId: instId as String?,
        fullName: ProfileCache.fullName,
      );

      if (mounted) {
        // No apagamos _isLoading: mantenemos el indicador hasta que la
        // navegación reemplace esta pantalla por la siguiente.
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No se pudo crear la institución. Intentá nuevamente.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.background,
      appBar: AppBar(
        title: const Text('Configuración de Institución'),
        centerTitle: true,
        backgroundColor: KaliColors.espresso,
        foregroundColor: KaliColors.warmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: KaliColors.warmWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Crea una nueva institución para empezar a gestionar tu estudio.',
                      style: KaliText.body(KaliColors.clayDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    KaliTextField(
                      label: 'NOMBRE DE LA INSTITUCIÓN',
                      hint: 'Ej. MiInst',
                      controller: _createNameCtrl,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KaliColors.espresso,
                          foregroundColor: KaliColors.warmWhite,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: KaliColors.warmWhite,
                                    strokeWidth: 2))
                            : const Text('CREAR Y CONTINUAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
