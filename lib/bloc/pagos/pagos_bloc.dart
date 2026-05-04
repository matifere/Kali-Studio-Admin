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

      final subscriptions = response
          .map<Subscription>((data) => Subscription.fromJson(data))
          .toList();

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
}
