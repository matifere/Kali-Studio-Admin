part of 'dashboard_bloc.dart';

class DashboardState {
  final int turnosActivosHoy;
  final int alumnosPresentesHoy;
  final int capacidadTotalHoy;
  final double ingresosMensuales;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.turnosActivosHoy = 0,
    this.alumnosPresentesHoy = 0,
    this.capacidadTotalHoy = 0,
    this.ingresosMensuales = 0.0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    int? turnosActivosHoy,
    int? alumnosPresentesHoy,
    int? capacidadTotalHoy,
    double? ingresosMensuales,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      turnosActivosHoy: turnosActivosHoy ?? this.turnosActivosHoy,
      alumnosPresentesHoy: alumnosPresentesHoy ?? this.alumnosPresentesHoy,
      capacidadTotalHoy: capacidadTotalHoy ?? this.capacidadTotalHoy,
      ingresosMensuales: ingresosMensuales ?? this.ingresosMensuales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get capacidadPorcentaje {
    if (capacidadTotalHoy == 0) return 0.0;
    return (alumnosPresentesHoy / capacidadTotalHoy).clamp(0.0, 1.0);
  }
}
