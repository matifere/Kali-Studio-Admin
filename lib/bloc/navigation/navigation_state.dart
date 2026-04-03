part of 'navigation_bloc.dart';

/// El estado actual de navegación del dashboard.
class NavigationState {
  /// Nombre de la página activa. Valores posibles:
  /// 'Panel', 'Alumnos', 'Turnos', 'Pagos'
  final String currentPage;

  const NavigationState(this.currentPage);
}
