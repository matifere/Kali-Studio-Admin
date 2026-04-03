import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kali_studio/data/mock_payments.dart';
import 'package:kali_studio/models/payment.dart';

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
    // TODO: reemplazar con llamada a Supabase cuando la tabla esté lista.
    emit(PagosLoaded(payments: kMockPayments));
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
