import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(KaliTheme.theme);

  /// Cambia el tema actual por uno nuevo (utilizado cuando cargamos desde Supabase o Caché)
  void updateTheme(ThemeData newTheme) {
    emit(newTheme);
  }

  /// TODO: Implementar lógica de Local-First (SharedPreferences) y Sincronización (Supabase)
  /// Esto se agregará en la Fase 7 del plan de implementación.
  Future<void> loadTheme() async {
    // 1. Leer de SharedPreferences rápido
    // 2. emit(cachedTheme) si existe
    // 3. Hacer request asíncrono a Supabase
    // 4. Si cambió, emit(newTheme) y sobrescribir SharedPreferences
  }
}
