import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/services/profile_cache.dart';

class ThemeState {
  final ThemeData themeData;
  final String themeId;
  final bool isDarkMode;

  const ThemeState({
    required this.themeData,
    required this.themeId,
    required this.isDarkMode,
  });
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'selected_theme';
  static const String _darkModeKey = 'is_dark_mode';

  ThemeCubit({required String initialThemeId, required bool initialIsDarkMode})
      : super(_buildState(initialThemeId, initialIsDarkMode));

  Future<void> changeTheme(String newThemeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newThemeId);
    emit(_buildState(newThemeId, state.isDarkMode));

    if (ProfileCache.role == 'sudo' && ProfileCache.institutionId != null) {
      try {
        await Supabase.instance.client
            .from('institutions')
            .update({'theme_id': newThemeId})
            .eq('id', ProfileCache.institutionId!);
      } catch (e) {
        // Ignorar el error
      }
    }
  }

  Future<void> syncTheme(String newThemeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newThemeId);
    emit(_buildState(newThemeId, state.isDarkMode));
  }

  Future<void> toggleDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
    emit(_buildState(state.themeId, enabled));
  }

  static ThemeState _buildState(String themeId, bool isDarkMode) {
    KaliColorsExtension colors;
    switch (themeId) {
      case 'ocean':
        colors = isDarkMode ? KaliColorsExtension.oceanDarkTheme : KaliColorsExtension.oceanTheme;
        break;
      case 'nature':
        colors = isDarkMode ? KaliColorsExtension.natureDarkTheme : KaliColorsExtension.natureTheme;
        break;
      case 'magenta':
        colors = isDarkMode ? KaliColorsExtension.magentaDarkTheme : KaliColorsExtension.magentaTheme;
        break;
      case 'classic':
        colors = isDarkMode ? KaliColorsExtension.classicDarkTheme : KaliColorsExtension.classicTheme;
        break;
      case 'default':
      default:
        colors = isDarkMode ? KaliColorsExtension.darkTheme : KaliColorsExtension.defaultTheme;
        break;
    }
    return ThemeState(
      themeData: KaliTheme.buildTheme(colors),
      themeId: themeId,
      isDarkMode: isDarkMode,
    );
  }
}

