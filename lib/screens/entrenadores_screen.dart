import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:google_fonts/google_fonts.dart';
import 'package:argrity/services/auth_service.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/common/kali_icon_button.dart';
import 'package:argrity/widgets/dashboard/top_navbar.dart';
import 'package:argrity/widgets/kali_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntrenadoresScreen extends StatelessWidget {
  const EntrenadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        const DashboardTopNavBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 40,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrenadores',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isSmall ? 36 : 46,
                    fontWeight: FontWeight.w600,
                    color: KaliColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestioná el equipo de entrenadores.',
                  style: KaliText.body(
                    KaliColors.espresso.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 32),
                const _EntrenadoresTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tabla de entrenadores ─────────────────────────────────────────────────────
class _EntrenadoresTable extends StatefulWidget {
  const _EntrenadoresTable();

  @override
  State<_EntrenadoresTable> createState() => _EntrenadoresTableState();
}

class _EntrenadoresTableState extends State<_EntrenadoresTable> {
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, is_active')
          .eq('role', 'admin')
          .order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _trainers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar entrenadores: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onTrainerCreated(Map<String, dynamic> trainer) {
    setState(() {
      _trainers = [..._trainers, trainer]..sort((a, b) =>
          (a['full_name'] as String? ?? '')
              .compareTo(b['full_name'] as String? ?? ''));
    });
  }

  Future<void> _deleteTrainer(Map<String, dynamic> trainer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar entrenador',
          style: KaliText.body(KaliColors.espresso,
              weight: FontWeight.w600, size: 18),
        ),
        content: Text(
          '¿Seguro que querés eliminar a ${trainer['full_name']}? Esta acción no se puede deshacer.',
          style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: KaliText.body(KaliColors.espresso)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: KaliText.body(const Color(0xFFD4685C),
                  weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deleted = await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', trainer['id'])
            .select('id');

        if (deleted.isEmpty) {
          throw Exception(
              'No se eliminó ningún registro. Verificá los permisos en Supabase.');
        }

        if (mounted) {
          _loadTrainers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrenador eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo eliminar el registro. Intentá nuevamente.'),
              duration: Duration(seconds: 8),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: LinearProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child:
                  Text(_error!, style: KaliText.body(const Color(0xFFD4685C))),
            )
          else if (_trainers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 40,
                      color: KaliColors.espresso.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay entrenadores registrados.',
                      style: KaliText.body(
                          KaliColors.espresso.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                const double minWidth = 600.0;
                final tableRows = Column(
                  children: [
                    _buildColumnHeaders(),
                    ..._trainers.map((t) => _TrainerRow(
                          trainer: t,
                          onDelete: () => _deleteTrainer(t),
                        )),
                    const SizedBox(height: 24),
                  ],
                );
                if (constraints.maxWidth < minWidth) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: minWidth, child: tableRows),
                  );
                }
                return tableRows;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Entrenadores del Estudio',
              style: KaliText.headingItalic(KaliColors.espresso, size: 22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _AddTrainerButton(onTrainerCreated: _onTrainerCreated),
          const SizedBox(width: 8),
          KaliIconButton(
            Icons.refresh_rounded,
            tooltip: 'Refrescar',
            onTap: _loadTrainers,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    final style = KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('NOMBRE', style: style)),
          Expanded(flex: 4, child: Text('CORREO', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 2, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}

// ── Fila de entrenador ────────────────────────────────────────────────────────
class _TrainerRow extends StatefulWidget {
  final Map<String, dynamic> trainer;
  final VoidCallback onDelete;

  const _TrainerRow({required this.trainer, required this.onDelete});

  @override
  State<_TrainerRow> createState() => _TrainerRowState();
}

class _TrainerRowState extends State<_TrainerRow> {
  bool _hovered = false;

  String get _initials {
    final name = (widget.trainer['full_name'] as String? ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.trainer['full_name'] as String? ?? 'Sin nombre';
    final email = widget.trainer['email'] as String? ?? '—';
    final isActive = widget.trainer['is_active'] as bool? ?? true;
    final statusColor =
        isActive ? const Color(0xFF5C9E6C) : const Color(0xFFD4685C);

    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? KaliColors.warmWhite : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          children: [
            // Nombre + avatar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: KaliColors.clay.withValues(alpha: 0.35),
                    child: Text(
                      _initials,
                      style: KaliText.body(
                        KaliColors.espresso,
                        weight: FontWeight.w700,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: KaliText.body(KaliColors.espresso,
                          weight: FontWeight.w600, size: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Correo
            Expanded(
              flex: 4,
              child: Text(
                email,
                style: KaliText.body(
                    KaliColors.espresso.withValues(alpha: 0.55),
                    size: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: KaliText.body(statusColor, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Acciones
            Expanded(
              flex: 2,
              child: KaliIconButton.action(
                Icons.delete_outline,
                tooltip: 'Eliminar',
                color: const Color(0xFFD4685C),
                onTap: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón Añadir Entrenador ───────────────────────────────────────────────────
class _AddTrainerButton extends StatefulWidget {
  final void Function(Map<String, dynamic>) onTrainerCreated;
  const _AddTrainerButton({required this.onTrainerCreated});

  @override
  State<_AddTrainerButton> createState() => _AddTrainerButtonState();
}

class _AddTrainerButtonState extends State<_AddTrainerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: () async {
          final trainer = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _CreateTrainerDialog(),
          );
          if (trainer != null) widget.onTrainerCreated(trainer);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? KaliColors.espressoL : KaliColors.espresso,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 15, color: KaliColors.warmWhite),
              const SizedBox(width: 6),
              Text(
                'Añadir Entrenador',
                style: KaliText.body(KaliColors.warmWhite,
                    weight: FontWeight.w600, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Diálogo de creación ───────────────────────────────────────────────────────
class _CreateTrainerDialog extends StatefulWidget {
  const _CreateTrainerDialog();

  @override
  State<_CreateTrainerDialog> createState() => _CreateTrainerDialogState();
}

class _CreateTrainerDialogState extends State<_CreateTrainerDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await SupaAuthClass().registrarEntrenador(email, password, name);

    if (result.startsWith('Ok:')) {
      final newId = result.substring(3);
      if (mounted) {
        Navigator.of(context).pop({
          'id': newId,
          'full_name': name,
          'email': email,
          'role': 'admin',
          'is_active': true,
        });
      }
    } else {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = result;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: KaliColors.warmWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Añadir Entrenador',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: KaliColors.espresso,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: KaliColors.espresso),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Se registrará con acceso de entrenador (rol admin).',
                style:
                    KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 28),

              KaliTextField(
                controller: _nameController,
                label: 'Nombre completo',
                hint: 'Ej. Valentina López',
              ),
              const SizedBox(height: 16),
              KaliTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'correo@ejemplo.com',
              ),
              const SizedBox(height: 16),
              KaliTextField(
                controller: _passwordController,
                label: 'Contraseña temporal',
                hint: 'Mínimo 6 caracteres',
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onSuffixTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: KaliText.body(const Color(0xFFD4685C), size: 13)),
              ],

              const SizedBox(height: 28),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: KaliText.body(
                          KaliColors.espresso.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MouseRegion(
                    cursor: _isLoading
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
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
                                'Registrar Entrenador',
                                style: KaliText.body(
                                  KaliColors.warmWhite,
                                  weight: FontWeight.w600,
                                  size: 13,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }
}
