import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/kali_text_field.dart';
import 'package:kali_studio/widgets/auth_wrapper.dart';
import 'package:kali_studio/screens/login_screen.dart';

class InstitutionSelectionScreen extends StatefulWidget {
  const InstitutionSelectionScreen({super.key});

  @override
  State<InstitutionSelectionScreen> createState() => _InstitutionSelectionScreenState();
}

class _InstitutionSelectionScreenState extends State<InstitutionSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _createNameCtrl = TextEditingController();
  final TextEditingController _joinIdCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameCtrl.dispose();
    _joinIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _createNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un nombre para la institución')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No session');

      final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

      // Usamos una función RPC para evitar el problema de RLS
      // (No podemos seleccionar la institución recién creada si nuestro perfil aún no tiene su ID)
      await Supabase.instance.client.rpc('create_institution', params: {
        'inst_name': name,
        'inst_slug': slug,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear institución: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoin() async {
    final instId = _joinIdCtrl.text.trim();
    if (instId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el ID de la institución')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No session');

      // Intentar actualizar directamente. Si falla por FK, es que no existe.
      await Supabase.instance.client.from('profiles').update({
        'institution_id': instId,
        'role': 'admin',
      }).eq('id', user.id);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo unir a la institución. Verifica que el ID sea correcto.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
              width: 500,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: KaliColors.espresso,
                    unselectedLabelColor: KaliColors.clayDark,
                    indicatorColor: KaliColors.espresso,
                    tabs: const [
                      Tab(text: 'Crear Institución'),
                      Tab(text: 'Unirse a Institución'),
                    ],
                  ),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab Crear
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Crea una nueva institución para empezar a gestionar tu estudio.',
                                style: KaliText.body(KaliColors.clayDark),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              KaliTextField(
                                label: 'NOMBRE DE LA INSTITUCIÓN',
                                hint: 'Ej. Kali Studio',
                                controller: _createNameCtrl,
                              ),
                              const Spacer(),
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
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: KaliColors.warmWhite, strokeWidth: 2))
                                    : const Text('CREAR Y CONTINUAR'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Unirse
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ingresa el ID proporcionado por el administrador de la institución.',
                                style: KaliText.body(KaliColors.clayDark),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              KaliTextField(
                                label: 'ID DE INSTITUCIÓN',
                                hint: 'xxxx-xxxx-xxxx-xxxx',
                                controller: _joinIdCtrl,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleJoin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KaliColors.espresso,
                                    foregroundColor: KaliColors.warmWhite,
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: KaliColors.warmWhite, strokeWidth: 2))
                                    : const Text('UNIRSE Y CONTINUAR'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
