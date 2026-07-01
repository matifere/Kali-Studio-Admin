import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:argrity/models/class_session.dart';
import 'package:argrity/bloc/turnos/turnos_bloc.dart';
import 'dart:math';

class TurnosRepository {
  final SupabaseClient _client;

  TurnosRepository({required SupabaseClient client}) : _client = client;

  Future<List<ClassSession>> getSessions({
    required DateTime start,
    required DateTime end,
    required String? instId,
    String? instructorFilter,
  }) async {
    final startIso = DateFormat('yyyy-MM-dd').format(start);
    final endIso = DateFormat('yyyy-MM-dd').format(end);

    const sessionSelect =
        '*, '
        'reservations(id, user_id, status, profiles:profiles!reservations_user_id_fkey(full_name))';

    var query = _client
        .from('class_sessions')
        .select(sessionSelect)
        // Ocultar solo las canceladas (feriados); el .or preserva las de status NULL legacy.
        .or('status.is.null,status.neq.cancelled')
        .gte('date', startIso)
        .lte('date', endIso);

    if (instId != null) {
      query = query.eq('institution_id', instId);
    }

    final response = instructorFilter != null
        ? await query.eq('instructor_name', instructorFilter)
        : await query;

    return response
        .map<ClassSession>((data) => ClassSession.fromJson(data))
        .toList();
  }

  String _generateUuid() {
    final random = Random();
    final list = List<int>.generate(16, (i) => random.nextInt(256));
    list[6] = (list[6] & 0x0f) | 0x40;
    list[8] = (list[8] & 0x3f) | 0x80;
    final hex = list.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> createSessions({
    required List<int> daysOfWeek,
    required DateTime currentWeekStart,
    required String startTime,
    required String endTime,
    required int recurrenceWeeks,
    required String name,
    required String? description,
    required String? instructorName,
    required int capacity,
    required String? instId,
  }) async {
    final insertData = <Map<String, dynamic>>[];
    final String groupId = _generateUuid();

    for (final dayIndex in daysOfWeek) {
      var baseDate = currentWeekStart.add(Duration(days: dayIndex));

      final parts = startTime.split(':');
      var startDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day,
          int.parse(parts[0]), int.parse(parts[1]));

      // Si la hora en la semana actual ya pasó, agendar desde la próxima semana
      if (startDateTime.isBefore(DateTime.now())) {
        baseDate = baseDate.add(const Duration(days: 7));
      }

      for (int i = 0; i < recurrenceWeeks; i++) {
        final d = baseDate.add(Duration(days: i * 7));
        final dateIso = DateFormat('yyyy-MM-dd').format(d);

        insertData.add({
          'group_id': groupId,
          'name': name,
          'description': description,
          'instructor_name': instructorName,
          'capacity': capacity,
          'start_time': startTime,
          'end_time': endTime,
          'date': dateIso,
          'status': 'scheduled',
          if (instId != null) 'institution_id': instId,
        });
      }
    }

    if (insertData.isNotEmpty) {
      await _client.from('class_sessions').insert(insertData);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('class_sessions').delete().eq('id', sessionId);
  }

  Future<void> deleteSessions(String groupId, DateTime fromDate) async {
    final dateIso = DateFormat('yyyy-MM-dd').format(fromDate);
    final endOfYearIso = '${fromDate.year}-12-31';

    await _client
        .from('class_sessions')
        .delete()
        .eq('group_id', groupId)
        .gte('date', dateIso)
        .lte('date', endOfYearIso);
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> data) async {
    await _client.from('class_sessions').update(data).eq('id', sessionId);
  }

  Future<void> updateSessions(
      String groupId, DateTime fromDate, Map<String, dynamic> data) async {
    final dateIso = DateFormat('yyyy-MM-dd').format(fromDate);
    final endOfYearIso = '${fromDate.year}-12-31';

    await _client
        .from('class_sessions')
        .update(data)
        .eq('group_id', groupId)
        .gte('date', dateIso)
        .lte('date', endOfYearIso);
  }

  /// Devuelve las sesiones futuras (desde el día siguiente a [session.date]
  /// hasta [untilDate] inclusive) de la misma serie recurrente: por group_id
  /// si el turno está agrupado, o por plantilla (nombre + horario + institución)
  /// cuando no lo está. Así la proyección funciona también para turnos sueltos.
  Future<List<Map<String, dynamic>>> getFutureSeriesSessions({
    required ClassSession session,
    required DateTime untilDate,
  }) async {
    final startIso = DateFormat('yyyy-MM-dd')
        .format(session.date.add(const Duration(days: 1)));
    final endIso = DateFormat('yyyy-MM-dd').format(untilDate);

    var query = _client
        .from('class_sessions')
        .select('id, date')
        .gte('date', startIso)
        .lte('date', endIso);

    if (session.groupId != null) {
      query = query.eq('group_id', session.groupId!);
    } else {
      query = query
          .eq('name', session.name)
          .eq('start_time', session.startTime);
      if (session.institutionId != null) {
        query = query.eq('institution_id', session.institutionId!);
      }
    }

    final res = await query.order('date', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> assignStudent({
    required String userId,
    required ClassSession session,
    required EnrollmentType enrollmentType,
  }) async {
    final inserts = <Map<String, dynamic>>[];

    // 1. Inscripción actual focalizada
    inserts.add({
      'user_id': userId,
      'session_id': session.id,
      'status': 'confirmed',
    });

    // 2. Si marcamos recurrencia, proyectamos sobre las clases futuras de la
    //    misma serie, desde el día siguiente a este turno hasta fin de mes (o
    //    de año), inscribiendo mientras al alumno le quede cupo mensual de
    //    reservas según su plan.
    if (enrollmentType != EnrollmentType.single) {
      // Fetch max reservations limit for the user
      final subResList = await _client
          .from('subscriptions')
          .select('plans(max_reservations_per_month)')
          .eq('user_id', userId)
          .inFilter('status', ['active', 'pending']);

      int maxRes = 0;
      for (final subRes in (subResList as List<dynamic>)) {
        if (subRes['plans'] != null &&
            subRes['plans']['max_reservations_per_month'] != null) {
          maxRes += subRes['plans']['max_reservations_per_month'] as int;
        }
      }

      // Only project if maxRes > 0
      if (maxRes > 0) {
        final DateTime untilDate;
        if (enrollmentType == EnrollmentType.month) {
          untilDate = DateTime(session.date.year, session.date.month + 1, 0);
        } else {
          untilDate = DateTime(session.date.year, 12, 31);
        }

        final futureSessions = await getFutureSeriesSessions(
          session: session,
          untilDate: untilDate,
        );

        if (futureSessions.isNotEmpty) {
          final currentMonthStart =
              DateTime(session.date.year, session.date.month, 1);
          final currentMonthStartIso =
              DateFormat('yyyy-MM-dd').format(currentMonthStart);

          // Fetch user's existing reservations to count per month correctly
          final existingRes = await _client
              .from('reservations')
              .select('session_id, class_sessions!inner(date)')
              .eq('user_id', userId)
              .gte('class_sessions.date', currentMonthStartIso);

          DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

          final Map<DateTime, int> resCount = {};
          final Set<String> enrolledSessionIds = {};

          for (var r in existingRes as List<dynamic>) {
            final d = DateTime.parse(r['class_sessions']['date']);
            final som = startOfMonth(d);
            resCount[som] = (resCount[som] ?? 0) + 1;
            if (r['session_id'] != null) {
              enrolledSessionIds.add(r['session_id'] as String);
            }
          }

          // Account for the current session we just added
          final currentSom = startOfMonth(session.date);
          resCount[currentSom] = (resCount[currentSom] ?? 0) + 1;
          enrolledSessionIds.add(session.id);

          for (final row in futureSessions) {
            final sessionId = row['id'] as String;
            if (enrolledSessionIds.contains(sessionId)) {
              continue;
            }

            final sessionDate = DateTime.parse(row['date']);
            final som = startOfMonth(sessionDate);
            final currCount = resCount[som] ?? 0;

            if (currCount < maxRes) {
              inserts.add({
                'user_id': userId,
                'session_id': sessionId,
                'status': 'confirmed',
              });
              resCount[som] = currCount + 1;
              enrolledSessionIds.add(sessionId);
            }
          }
        }
      }
    }

    if (inserts.isNotEmpty) {
      await _client.from('reservations').insert(inserts);
    }
  }

  Future<void> removeStudent(String reservationId) async {
    await _client.from('reservations').delete().eq('id', reservationId);
  }

  /// Cancela todas las clases de [date] (feriado) y devuelve el crédito a cada
  /// alumno afectado. Corre en el servidor de forma atómica (RPC security-definer)
  /// y notifica a los alumnos (dispara el push). Devuelve el JSON del RPC con la
  /// cantidad de clases y reservas canceladas.
  Future<Map<String, dynamic>> cancelDayAsHoliday(
      DateTime date, String? reason) async {
    final res = await _client.rpc('cancel_day_as_holiday', params: {
      'p_date': DateFormat('yyyy-MM-dd').format(date),
      'p_reason': (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> toggleAttendance(
      String reservationId, String nextStatus) async {
    await _client
        .from('reservations')
        .update({'status': nextStatus}).eq('id', reservationId);
  }
}
