import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/models/student.dart';

class AlumnosRepository {
  final SupabaseClient _client;

  AlumnosRepository({required SupabaseClient client}) : _client = client;

  Future<List<Student>> getStudents(String? instId) async {
    const selectQuery = '''
      id, avatar_url, full_name, email, is_active, created_at, patologias,
      subscriptions!subscriptions_user_id_fkey(status, end_date, plans(name)),
      reservations!reservations_user_id_fkey(status, class_sessions(name, date, start_time))
    ''';

    var query = _client.from('profiles').select(selectQuery).eq('role', 'client');
    
    if (instId != null) {
      query = query.eq('institution_id', instId);
    }
    
    final response = await query;

    return response.map<Student>((data) => Student.fromJson(data)).toList();
  }
}
