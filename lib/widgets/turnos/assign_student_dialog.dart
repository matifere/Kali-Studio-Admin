import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/widgets/common/avatar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignStudentDialog extends StatefulWidget {
  final ClassSession session;

  const AssignStudentDialog({super.key, required this.session});

  @override
  State<AssignStudentDialog> createState() => _AssignStudentDialogState();
}

class _AssignStudentDialogState extends State<AssignStudentDialog> {
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isLoading = true;
  String? _error;
  EnrollmentType _enrollmentType = EnrollmentType.single;
  bool _canProject = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final client = Supabase.instance.client;
      final sessionDate = widget.session.date;
      final monthStart = DateTime(sessionDate.year, sessionDate.month, 1);
      final monthEnd = DateTime(sessionDate.year, sessionDate.month + 1, 0);
      final startIso = monthStart.toIso8601String().split('T')[0];
      final endIso = monthEnd.toIso8601String().split('T')[0];

      // 1. Fetch profiles
      final profilesRes = await client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('role', 'client')
          .order('full_name', ascending: true);

      // 2. Fetch active/pending subscriptions
      final subsRes = await client
          .from('subscriptions')
          .select('user_id, status, plans(max_reservations_per_month)')
          .inFilter('status', ['active', 'pending']);

      // Map subscriptions by user_id and sum their max_reservations
      final Map<String, int> userMaxRes = {};
      final Set<String> usersWithPlan = {};
      for (var sub in (subsRes as List<dynamic>)) {
        final uid = sub['user_id'] as String;
        usersWithPlan.add(uid);
        final plansData = sub['plans'];
        if (plansData != null && plansData['max_reservations_per_month'] != null) {
          userMaxRes[uid] = (userMaxRes[uid] ?? 0) + (plansData['max_reservations_per_month'] as int);
        }
      }

      // 3. Fetch reservations for the month
      final resRes = await client
          .from('reservations')
          .select('user_id, class_sessions!inner(date)')
          .gte('class_sessions.date', startIso)
          .lte('class_sessions.date', endIso);

      // Count reservations per user
      final Map<String, int> userReservations = {};
      for (var r in (resRes as List<dynamic>)) {
        final uid = r['user_id'] as String;
        userReservations[uid] = (userReservations[uid] ?? 0) + 1;
      }

      // 4b. ¿Hay más sesiones de esta misma serie en lo que resta del mes?
      //     Si las hay, ofrecemos proyectar la inscripción; si no, no aparece.
      final seriesStartIso =
          sessionDate.add(const Duration(days: 1)).toIso8601String().split('T')[0];
      var seriesQuery = client
          .from('class_sessions')
          .select('id')
          .gte('date', seriesStartIso)
          .lte('date', endIso);
      if (widget.session.groupId != null) {
        seriesQuery = seriesQuery.eq('group_id', widget.session.groupId!);
      } else {
        seriesQuery = seriesQuery
            .eq('name', widget.session.name)
            .eq('start_time', widget.session.startTime);
        if (widget.session.institutionId != null) {
          seriesQuery = seriesQuery.eq('institution_id', widget.session.institutionId!);
        }
      }
      final seriesRes = await seriesQuery.limit(1);
      final canProject = (seriesRes as List).isNotEmpty;

      // 4. Filtrar los que ya están anotados en esta sesión
      final enrolledIds = widget.session.enrolledStudents.map((e) => e.userId).toSet();

      final available = (profilesRes as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .where((p) => !enrolledIds.contains(p['id']))
          .map((p) {
            final uid = p['id'] as String;
            String? disabledReason;
            int maxRes = 0;
            int currRes = userReservations[uid] ?? 0;

            if (!usersWithPlan.contains(uid)) {
              disabledReason = 'Sin plan activo';
            } else {
              maxRes = userMaxRes[uid] ?? 0;
              if (maxRes > 0 && currRes >= maxRes) {
                disabledReason = 'Límite mensual alcanzado';
              }
            }

            p['disabledReason'] = disabledReason;
            p['currRes'] = currRes;
            p['maxRes'] = maxRes;
            return p;
          })
          .toList();

      if (mounted) {
        setState(() {
          _profiles = available;
          _filteredProfiles = available;
          _canProject = canProject;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar alumnos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProfiles = _profiles);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredProfiles = _profiles.where((p) {
        final name = (p['full_name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  void _assign(String userId) {
    context.read<TurnosBloc>().add(
      TurnoStudentAssigned(
        userId: userId,
        session: widget.session,
        enrollmentType: _enrollmentType,
      )
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alumno inscripto correctamente')));
  }

  /// Permite al admin forzar la inscripción de un alumno que no cumple los
  /// requisitos (sin plan activo o con el límite mensual alcanzado).
  Future<void> _confirmOverride(String userId, String name, String reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Inscribir sin créditos', style: KaliText.heading(KaliColors.espresso, size: 20)),
        content: Text(
          '$name no cumple los requisitos ($reason). '
          '¿Inscribirlo de todas formas? Como admin podés forzar la inscripción.',
          style: KaliText.body(KaliColors.espresso),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Inscribir igual', style: KaliText.body(KaliColors.espresso, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _assign(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inscribir Alumno',
                  style: KaliText.heading(KaliColors.espresso, size: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Asignar a: ${widget.session.name}',
              style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_canProject || widget.session.groupId != null) ...[
              Text('Opciones de inscripción recurrentes', style: KaliText.body(KaliColors.espresso, size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<EnrollmentType>(
                initialValue: _enrollmentType,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: KaliColors.espresso.withValues(alpha: 0.1)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: EnrollmentType.single,
                    child: Text('Solo a esta clase'),
                  ),
                  DropdownMenuItem(
                    value: EnrollmentType.month,
                    child: Text('Proyectar durante todo el mes'),
                  ),
                  DropdownMenuItem(
                    value: EnrollmentType.year,
                    child: Text('Proyectar durante todo el año'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _enrollmentType = v);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _filteredProfiles.isEmpty
                    ? Center(child: Text('No se encontraron alumnos disponibles', style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5))))
                    : ListView.separated(
                        itemCount: _filteredProfiles.length,
                        separatorBuilder: (_, __) => Divider(color: KaliColors.espresso.withValues(alpha: 0.1)),
                        itemBuilder: (context, index) {
                          final p = _filteredProfiles[index];
                          final name = p['full_name'] ?? 'Sin nombre';
                          final disabledReason = p['disabledReason'] as String?;
                          final currRes = p['currRes'] as int?;
                          final maxRes = p['maxRes'] as int?;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: KaliColors.clay,
                              backgroundImage: AvatarProvider.fromUrl(p['avatar_url']),
                              child: p['avatar_url'] == null 
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12))
                                : null,
                            ),
                            title: Text(name, style: KaliText.body(
                              KaliColors.espresso.withValues(alpha: disabledReason != null ? 0.5 : 1.0), 
                              weight: FontWeight.w600
                            )),
                            subtitle: disabledReason != null
                                ? Text(disabledReason, style: TextStyle(color: Colors.red[700], fontSize: 12))
                                : Text(
                                    (maxRes ?? 0) > 0
                                        ? '$currRes/$maxRes reservas este mes'
                                        : 'Con plan activo',
                                    style: TextStyle(
                                      color: ((maxRes ?? 0) > 0 && (currRes ?? 0) >= maxRes!)
                                          ? Colors.orange[700]
                                          : KaliColors.clay,
                                      fontSize: 12,
                                    ),
                                  ),
                            trailing: TextButton(
                              onPressed: disabledReason != null
                                  ? () => _confirmOverride(p['id'], name, disabledReason)
                                  : () => _assign(p['id']),
                              style: disabledReason != null
                                  ? TextButton.styleFrom(foregroundColor: Colors.orange[800])
                                  : null,
                              child: Text(disabledReason != null ? 'Inscribir igual' : 'Inscribir'),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
