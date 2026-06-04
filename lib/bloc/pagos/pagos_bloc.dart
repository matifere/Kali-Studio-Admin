import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/models/subscription.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'pagos_event.dart';
part 'pagos_state.dart';

/// Gestiona la carga de pagos y la paginación de la tabla de transacciones.
///
/// Actualmente usa datos mock. Cuando se conecte a Supabase,
/// solo hay que cambiar el contenido de [_onLoadRequested].
class PagosBloc extends Bloc<PagosEvent, PagosState> {
  PagosBloc() : super(PagosInitial()) {
    on<PagosLoadRequested>(_onLoadRequested);
    on<PagosPageChanged>(_onPageChanged);
    on<PagosSubscriptionStatusChanged>(_onSubscriptionStatusChanged);
    on<PagosFiltersChanged>(_onFiltersChanged);
    on<PagosSearchChanged>(_onSearchChanged);
  }

  // ── Carga inicial ──────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    PagosLoadRequested event,
    Emitter<PagosState> emit,
  ) async {
    if (Supabase.instance.client.auth.currentSession == null) {
      emit(PagosLoaded(payments: []));
      return;
    }
    emit(PagosLoading());
    try {
      final instId = ProfileCache.institutionId;

      // Incluimos institution_id en el join de profiles para poder filtrar
      // por tenant después de recibir la respuesta (las suscripciones no tienen
      // institution_id propio; la pertenencia se determina vía el perfil del alumno).
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select(
            'id, user_id, status, start_date, end_date, plan_id, '
            'profiles:profiles!subscriptions_user_id_fkey(id, full_name, avatar_url, institution_id), '
            'plans(id, name, price, currency)',
          );

      // Filtro client-side por institución como defensa en profundidad
      // (el filtro definitivo debe ser RLS en Supabase).
      final tenantRows = instId != null
          ? response.where((row) {
              final p = row['profiles'];
              if (p is Map) return p['institution_id'] == instId;
              if (p is List && p.isNotEmpty) {
                return p.first['institution_id'] == instId;
              }
              return false;
            }).toList()
          : response;

      final subscriptions = tenantRows
          .map<Subscription>((row) => Subscription.fromJson(row))
          .toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiredIds = <String>[];

      final updatedSubscriptions = subscriptions.map((sub) {
        final endDate = DateTime(sub.endDate.year, sub.endDate.month, sub.endDate.day);
        if (sub.status != 'expired' && sub.status != 'cancelled' && today.isAfter(endDate)) {
          expiredIds.add(sub.id);
          return sub.copyWith(status: 'expired');
        }
        return sub;
      }).toList();

      if (expiredIds.isNotEmpty) {
        Supabase.instance.client
            .from('subscriptions')
            .update({'status': 'expired'})
            .inFilter('id', expiredIds)
            .catchError((_) {});
      }

      emit(PagosLoaded(payments: updatedSubscriptions));
    } catch (_) {
      emit(PagosLoaded(payments: []));
    }
  }

  // ── Cambio de página ───────────────────────────────────────────────────────
  void _onPageChanged(
    PagosPageChanged event,
    Emitter<PagosState> emit,
  ) {
    final current = state;
    if (current is PagosLoaded) {
      emit(current.copyWithPage(event.page));
    }
  }

  // ── Cambio de estado de suscripción ────────────────────────────────────────
  Future<void> _onSubscriptionStatusChanged(
    PagosSubscriptionStatusChanged event,
    Emitter<PagosState> emit,
  ) async {
    final current = state;
    if (current is PagosLoaded) {
      try {
        await Supabase.instance.client
            .from('subscriptions')
            .update({'status': event.newStatus})
            .eq('id', event.subscriptionId);

        final updatedList = current.payments.map((sub) {
          if (sub.id == event.subscriptionId) {
            return sub.copyWith(status: event.newStatus);
          }
          return sub;
        }).toList();

        emit(PagosLoaded(
          payments: updatedList,
          currentPage: current.currentPage,
        ));
      } catch (_) {
        // El estado local ya refleja el cambio; si falla el server, la próxima carga lo corregirá
      }
    }
  }

  // ── Cambio de filtros ──────────────────────────────────────────────────────
  void _onFiltersChanged(
    PagosFiltersChanged event,
    Emitter<PagosState> emit,
  ) {
    final current = state;
    if (current is PagosLoaded) {
      emit(current.copyWith(
        selectedStatuses: event.selectedStatuses,
        currentPage: 1, // Reset page on filter change
      ));
    }
  }

  // ── Búsqueda por nombre ────────────────────────────────────────────────────
  void _onSearchChanged(
    PagosSearchChanged event,
    Emitter<PagosState> emit,
  ) {
    final current = state;
    if (current is PagosLoaded) {
      emit(current.copyWith(
        searchQuery: event.query,
        currentPage: 1, // Reset page on search change
      ));
    }
  }
}
