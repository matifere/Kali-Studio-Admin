part of 'dashboard_bloc.dart';

class DashboardState {
  final int turnosActivosHoy;
  final int alumnosPresentesHoy;
  final int capacidadTotalHoy;
  final double ingresosMensuales;
  final int vencimientosProximos;
  final bool isLoading;
  final bool hasLoaded;
  final String? error;
  final String? joinCode;

  DashboardState({
    this.turnosActivosHoy = 0,
    this.alumnosPresentesHoy = 0,
    this.capacidadTotalHoy = 0,
    this.ingresosMensuales = 0.0,
    this.vencimientosProximos = 0,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
    this.joinCode,
  });

  DashboardState copyWith({
    int? turnosActivosHoy,
    int? alumnosPresentesHoy,
    int? capacidadTotalHoy,
    double? ingresosMensuales,
    int? vencimientosProximos,
    bool? isLoading,
    bool? hasLoaded,
    String? error,
    String? joinCode,
  }) {
    return DashboardState(
      turnosActivosHoy: turnosActivosHoy ?? this.turnosActivosHoy,
      alumnosPresentesHoy: alumnosPresentesHoy ?? this.alumnosPresentesHoy,
      capacidadTotalHoy: capacidadTotalHoy ?? this.capacidadTotalHoy,
      ingresosMensuales: ingresosMensuales ?? this.ingresosMensuales,
      vencimientosProximos: vencimientosProximos ?? this.vencimientosProximos,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
      joinCode: joinCode ?? this.joinCode,
    );
  }

  double get capacidadPorcentaje {
    if (capacidadTotalHoy == 0) return 0.0;
    return (alumnosPresentesHoy / capacidadTotalHoy).clamp(0.0, 1.0);
  }
}
