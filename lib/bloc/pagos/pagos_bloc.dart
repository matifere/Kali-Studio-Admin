import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/models/subscription.dart';
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

  // ── Carga inicial (mock — listo para Supabase) ─────────────────────────────
  Future<void> _onLoadRequested(
    PagosLoadRequested event,
    Emitter<PagosState> emit,
  ) async {
    emit(PagosLoading());
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select('*, profiles!subscriptions_user_id_fkey(*), plans(*)')
          .order('created_at', ascending: false);

      var subscriptions = response
          .map<Subscription>((data) => Subscription.fromJson(data))
          .toList();

      // Check for automatic expiration
      final now = DateTime.now();
      bool anyUpdated = false;

      final updatedSubscriptions = <Subscription>[];
      for (var sub in subscriptions) {
        // We consider it overdue if now is after the end date (ignoring time)
        // using the end of the day or just comparing dates.
        final today = DateTime(now.year, now.month, now.day);
        final endDate = DateTime(sub.endDate.year, sub.endDate.month, sub.endDate.day);
        
        if (sub.status != 'expired' && sub.status != 'cancelled') {
          if (today.isAfter(endDate)) {
            // Update in Supabase asynchronously (don't await to avoid blocking UI)
            Supabase.instance.client
                .from('subscriptions')
                .update({'status': 'expired'})
                .eq('id', sub.id)
                .then((_) => debugPrint('Auto-updated ${sub.id} to expired'))
                .catchError((e) => debugPrint('Error auto-updating ${sub.id}: $e'));

            updatedSubscriptions.add(sub.copyWith(status: 'expired'));
            anyUpdated = true;
            continue;
          }
        }
        updatedSubscriptions.add(sub);
      }

      if (anyUpdated) {
        subscriptions = updatedSubscriptions;
      }

      emit(PagosLoaded(payments: subscriptions));
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      // Si hay error en Supabase o parseo, emitimos estado con error (se podría crear PagosError si hace falta)
      // Por el momento, si falla podemos dejar la lista vacía o manejarlo si existiese PagosError.
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
      } catch (e) {
        debugPrint('Error updating subscription status: $e');
        // Opcional: mostrar un error o revertir optimísticamente
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
