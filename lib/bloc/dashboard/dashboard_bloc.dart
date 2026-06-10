import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:argrity/services/profile_cache.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardState()) {
    on<DashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (!state.hasLoaded) {
      emit(state.copyWith(isLoading: true, error: null));
    }
    try {
      final now = DateTime.now();
      final todayIso = DateFormat('yyyy-MM-dd').format(now);
      final firstDayOfMonth = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      final supabase = Supabase.instance.client;

      // Las stats deben ser solo de la institución del usuario. payments no
      // tiene institution_id propio: la pertenencia se determina vía el perfil
      // del alumno (mismo criterio que PagosBloc).
      final instId = ProfileCache.institutionId;

      // Ambas queries en paralelo
      var sessionsQuery = supabase
          .from('class_sessions')
          .select('id, capacity, reservations(id, status)')
          .eq('date', todayIso)
          .neq('status', 'cancelled');
      if (instId != null) {
        sessionsQuery = sessionsQuery.eq('institution_id', instId);
      }
      final sessionsFuture = sessionsQuery;

      var paymentsQuery = supabase
          .from('payments')
          .select('amount, profiles!payments_user_id_fkey!inner(institution_id)')
          .gte('payment_date', firstDayOfMonth)
          .eq('status', 'completed');
      if (instId != null) {
        paymentsQuery = paymentsQuery.eq('profiles.institution_id', instId);
      }
      final paymentsFuture = paymentsQuery;

      final sessions = await sessionsFuture as List<dynamic>;
      final paymentsData = await paymentsFuture;

      int turnosHoy = sessions.length;
      int capacidadTotal = 0;
      int alumnosPresentes = 0;

      for (final session in sessions) {
        capacidadTotal += (session['capacity'] as int? ?? 0);
        final reservations = session['reservations'] as List<dynamic>? ?? [];
        for (final res in reservations) {
          if (res['status'] == 'attended') alumnosPresentes++;
        }
      }

      double ingresos = 0.0;
      for (final p in paymentsData) {
        ingresos += (p['amount'] as num).toDouble();
      }

      emit(state.copyWith(
        turnosActivosHoy: turnosHoy,
        alumnosPresentesHoy: alumnosPresentes,
        capacidadTotalHoy: capacidadTotal,
        ingresosMensuales: ingresos,
        isLoading: false,
        hasLoaded: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al cargar estadísticas: $e',
      ));
    }
  }
}
