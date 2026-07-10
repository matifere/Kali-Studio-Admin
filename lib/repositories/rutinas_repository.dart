import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/models/routine.dart';

class RutinasRepository {
  final SupabaseClient _client;

  RutinasRepository({required SupabaseClient client}) : _client = client;

  /// Alumnos de la institución (listado liviano para la sección Rutinas).
  Future<List<RoutineStudent>> getStudents(String? instId) async {
    var query = _client
        .from('profiles')
        .select('id, full_name, avatar_url, is_active')
        .eq('role', 'client');

    if (instId != null) {
      query = query.eq('institution_id', instId);
    }

    final response = await query.order('full_name', ascending: true);
    return response
        .map<RoutineStudent>((data) => RoutineStudent.fromJson(data))
        .toList();
  }

  /// Catálogo de rutinas de la institución.
  Future<List<Routine>> getRoutines(String? instId) async {
    var query = _client
        .from('routines')
        .select('id, name, description, exercises, created_at');

    if (instId != null) {
      query = query.eq('institution_id', instId);
    }

    final response = await query.order('name', ascending: true);
    return response.map<Routine>((data) => Routine.fromJson(data)).toList();
  }

  /// Asignaciones vigentes, indexadas por id de alumno.
  Future<Map<String, RoutineAssignment>> getAssignments() async {
    final response = await _client.from('routine_assignments').select('''
      id, user_id, assigned_at,
      routines(id, name, description, exercises, created_at)
    ''');

    final map = <String, RoutineAssignment>{};
    for (final data in response) {
      final assignment = RoutineAssignment.fromJson(data);
      map[assignment.userId] = assignment;
    }
    return map;
  }

  Future<Routine> createRoutine({
    required String institutionId,
    required String name,
    String? description,
    List<String> exercises = const [],
  }) async {
    final response = await _client
        .from('routines')
        .insert({
          'institution_id': institutionId,
          'name': name,
          'description': description,
          'exercises': exercises,
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id, name, description, exercises, created_at')
        .single();

    return Routine.fromJson(response);
  }

  Future<void> deleteRoutine(String routineId) async {
    await _client.from('routines').delete().eq('id', routineId);
  }

  /// Asigna (o reemplaza) la rutina del alumno — upsert sobre user_id.
  Future<void> assignRoutine({
    required String userId,
    required String routineId,
  }) async {
    await _client.from('routine_assignments').upsert(
      {
        'user_id': userId,
        'routine_id': routineId,
        'assigned_by': _client.auth.currentUser?.id,
        'assigned_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<void> unassignRoutine(String userId) async {
    await _client.from('routine_assignments').delete().eq('user_id', userId);
  }
}
