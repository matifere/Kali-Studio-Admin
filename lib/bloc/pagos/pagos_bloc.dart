import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/models/subscription.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/repositories/pagos_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed only for auth checks

part 'pagos_event.dart';
part 'pagos_state.dart';

/// Gestiona la carga de pagos y la paginación de la tabla de transacciones.
///
/// Actualmente usa datos mock. Cuando se conecte a Supabase,
/// solo hay que cambiar el contenido de [_onLoadRequested].
class PagosBloc extends Bloc<PagosEvent, PagosState> {
  final PagosRepository _repository;

  PagosBloc({required PagosRepository repository})
      : _repository = repository,
        super(PagosInitial()) {
    on<PagosLoadRequested>(_onLoadRequested);
    on<PagosPageChanged>(_onPageChanged);
    on<PagosSubscriptionStatusChanged>(_onSubscriptionStatusChanged);
    on<PagosSubscriptionEdited>(_onSubscriptionEdited);
    on<PagosSubscriptionDeleted>(_onSubscriptionDeleted);
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
      final subscriptions = await _repository.getSubscriptions(instId);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiredIds = <String>[];

      final updatedSubscriptions = subscriptions.map((sub) {
        final endDate =
            DateTime(sub.endDate.year, sub.endDate.month, sub.endDate.day);
        if (sub.status != 'expired' &&
            sub.status != 'cancelled' &&
            today.isAfter(endDate)) {
          expiredIds.add(sub.id);
          return sub.copyWith(status: 'expired');
        }
        return sub;
      }).toList();

      if (expiredIds.isNotEmpty) {
        await _repository.markSubscriptionsExpired(expiredIds);
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
        await _repository.updateSubscriptionStatus(
            event.subscriptionId, event.newStatus);

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

  // ── Edición de la asignación (plan y/o fechas) ──────────────────────────────
  Future<void> _onSubscriptionEdited(
    PagosSubscriptionEdited event,
    Emitter<PagosState> emit,
  ) async {
    final current = state;
    if (current is! PagosLoaded) return;
    try {
      await _repository.updateSubscription(
        subscriptionId: event.subscriptionId,
        planId: event.planId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final updatedList = current.payments.map((sub) {
        if (sub.id == event.subscriptionId) {
          return sub.copyWith(
            planName: event.planName,
            price: event.price,
            currency: event.currency,
            startDate: event.startDate,
            endDate: event.endDate,
          );
        }
        return sub;
      }).toList();

      emit(current.copyWith(payments: updatedList));
    } catch (_) {
      // Si falla el server, la próxima carga corrige el estado local.
    }
  }

  // ── Eliminación de la asignación ────────────────────────────────────────────
  Future<void> _onSubscriptionDeleted(
    PagosSubscriptionDeleted event,
    Emitter<PagosState> emit,
  ) async {
    final current = state;
    if (current is! PagosLoaded) return;
    try {
      await _repository.deleteSubscription(event.subscriptionId);

      final updatedList = current.payments
          .where((sub) => sub.id != event.subscriptionId)
          .toList();

      emit(current.copyWith(payments: updatedList));
    } catch (_) {
      // Si falla el server, la próxima carga corrige el estado local.
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
