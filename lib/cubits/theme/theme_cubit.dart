import 'package:argrity/theme/kali_theme.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeData> {
  static const String _themeKey = 'selected_theme';

  ThemeCubit({required String initialThemeId}) 
      : super(_buildTheme(initialThemeId));

  /// Cambia el tema actual y lo guarda en SharedPreferences
  Future<void> changeTheme(String newThemeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newThemeId);
    emit(_buildTheme(newThemeId));
  }

  static ThemeData _buildTheme(String themeId) {
    KaliColorsExtension colors;
    switch (themeId) {
      case 'dark':
        colors = KaliColorsExtension.darkTheme;
        break;
      case 'ocean':
        colors = KaliColorsExtension.oceanTheme;
        break;
      case 'default':
      default:
        colors = KaliColorsExtension.defaultTheme;
        break;
    }
    return KaliTheme.buildTheme(colors);
  }
}
