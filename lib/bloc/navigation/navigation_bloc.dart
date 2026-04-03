import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

/// Gestiona qué pestaña está activa en el dashboard.
///
/// El estado inicial es 'Panel'. Cuando [DashboardSidebar] dispara
/// [NavigationPageChanged], este BLoC emite el nuevo [NavigationState].
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState('Panel')) {
    on<NavigationPageChanged>(_onPageChanged);
  }

  void _onPageChanged(
    NavigationPageChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(NavigationState(event.page));
  }
}
