import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/services/profile_cache.dart';

/// Detalle de una clase de hoy para el chat de Chimpy.
class ChimpySessionInfo {
  final String name;
  final String startTime; // 'HH:mm'
  final int capacity;
  final int reservas; // reservas no canceladas (incluye no-show)
  final int presentes; // status == 'attended'
  final int noShows; // status == 'no_show'

  const ChimpySessionInfo({
    required this.name,
    required this.startTime,
    required this.capacity,
    required this.reservas,
    required this.presentes,
    required this.noShows,
  });

  double get ocupacion =>
      capacity == 0 ? 0 : (reservas / capacity).clamp(0.0, 1.0);
}

/// Estadísticas reales del día que consume el chat de Chimpy.
class ChimpyDailyStats {
  final List<ChimpySessionInfo> sesiones;
  final int pagosHoy;
  final double montoPagosHoy;
  final int alumnosNuevosHoy;
  final int cancelacionesHoy;

  /// Reservas creadas hoy (para cualquier fecha). Null si la columna
  /// created_at no está disponible en reservations.
  final int? reservasHechasHoy;

  const ChimpyDailyStats({
    required this.sesiones,
    required this.pagosHoy,
    required this.montoPagosHoy,
    required this.alumnosNuevosHoy,
    required this.cancelacionesHoy,
    required this.reservasHechasHoy,
  });

  int get totalReservas => sesiones.fold(0, (sum, s) => sum + s.reservas);
  int get totalPresentes => sesiones.fold(0, (sum, s) => sum + s.presentes);
  int get totalNoShows => sesiones.fold(0, (sum, s) => sum + s.noShows);
  int get totalCapacidad => sesiones.fold(0, (sum, s) => sum + s.capacity);

  /// Mismo criterio que la stat card del dashboard: presentes / capacidad.
  double get ocupacion => totalCapacidad == 0
      ? 0
      : (totalPresentes / totalCapacidad).clamp(0.0, 1.0);

  ChimpySessionInfo? get turnoMasLleno {
    ChimpySessionInfo? top;
    for (final s in sesiones) {
      if (s.capacity == 0) continue;
      if (top == null || s.ocupacion > top.ocupacion) top = s;
    }
    return top;
  }
}

/// Consulta las métricas reales del día en Supabase (scope de la institución).
class ChimpyService {
  ChimpyService._();

  static Future<ChimpyDailyStats> fetchToday() async {
    final supabase = Supabase.instance.client;
    final instId = ProfileCache.institutionId;

    final now = DateTime.now();
    final todayIso = DateFormat('yyyy-MM-dd').format(now);
    // Inicio del día local en UTC para comparar contra timestamptz.
    final dayStartUtc =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    // Mismo filtro que DashboardBloc para que los números coincidan con las
    // stat cards.
    var sessionsQuery = supabase
        .from('class_sessions')
        .select('name, start_time, capacity, reservations(status)')
        .eq('date', todayIso)
        .neq('status', 'cancelled');
    if (instId != null) {
      sessionsQuery = sessionsQuery.eq('institution_id', instId);
    }

    var paymentsQuery = supabase
        .from('payments')
        .select('amount')
        .eq('status', 'completed')
        .gte('payment_date', dayStartUtc);
    if (instId != null) {
      paymentsQuery = paymentsQuery.eq('institution_id', instId);
    }

    var newStudentsQuery = supabase
        .from('profiles')
        .select('id')
        .eq('role', 'client')
        .gte('created_at', dayStartUtc);
    if (instId != null) {
      newStudentsQuery = newStudentsQuery.eq('institution_id', instId);
    }

    // Cancelaciones hechas hoy (cancelled_at lo setea la app y el RPC de
    // feriados). Se scopea vía la sesión porque reservations no tiene
    // institution_id propio.
    var cancelQuery = supabase
        .from('reservations')
        .select('id, class_sessions!inner(institution_id)')
        .eq('status', 'cancelled')
        .gte('cancelled_at', dayStartUtc);
    if (instId != null) {
      cancelQuery = cancelQuery.eq('class_sessions.institution_id', instId);
    }

    final results = await Future.wait([
      sessionsQuery.order('start_time', ascending: true),
      paymentsQuery,
      newStudentsQuery,
      cancelQuery,
    ]);

    // Reservas creadas hoy: query aparte y tolerante, por si created_at no
    // existe en reservations (no debe romper el resto del chat).
    int? reservasHechasHoy;
    try {
      var madeTodayQuery = supabase
          .from('reservations')
          .select('id, class_sessions!inner(institution_id)')
          .gte('created_at', dayStartUtc);
      if (instId != null) {
        madeTodayQuery =
            madeTodayQuery.eq('class_sessions.institution_id', instId);
      }
      reservasHechasHoy = (await madeTodayQuery as List<dynamic>).length;
    } catch (_) {
      reservasHechasHoy = null;
    }

    final sesiones = <ChimpySessionInfo>[];
    for (final row in results[0] as List<dynamic>) {
      final reservations = row['reservations'] as List<dynamic>? ?? [];
      int reservas = 0;
      int presentes = 0;
      int noShows = 0;
      for (final res in reservations) {
        final status = res['status'] as String?;
        if (status == 'cancelled') continue;
        reservas++;
        if (status == 'attended') presentes++;
        if (status == 'no_show') noShows++;
      }
      final rawTime = row['start_time'] as String? ?? '';
      sesiones.add(ChimpySessionInfo(
        name: row['name'] as String? ?? 'Turno',
        startTime: rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime,
        capacity: row['capacity'] as int? ?? 0,
        reservas: reservas,
        presentes: presentes,
        noShows: noShows,
      ));
    }

    double montoPagos = 0;
    final pagos = results[1] as List<dynamic>;
    for (final p in pagos) {
      montoPagos += ((p['amount'] as num?) ?? 0).toDouble();
    }

    return ChimpyDailyStats(
      sesiones: sesiones,
      pagosHoy: pagos.length,
      montoPagosHoy: montoPagos,
      alumnosNuevosHoy: (results[2] as List<dynamic>).length,
      cancelacionesHoy: (results[3] as List<dynamic>).length,
      reservasHechasHoy: reservasHechasHoy,
    );
  }
}
