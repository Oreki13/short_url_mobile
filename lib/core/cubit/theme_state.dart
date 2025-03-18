import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

// State
class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

// Cubit
class ThemeCubit extends Cubit<ThemeState> {
  final SharedPreferences _preferences;
  static const String _themeKey = 'theme_mode';

  ThemeCubit(this._preferences) : super(const ThemeState(ThemeMode.dark)) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final storedThemeIndex = _preferences.getInt(_themeKey);
    if (storedThemeIndex != null) {
      final themeMode = ThemeMode.values[storedThemeIndex];
      emit(ThemeState(themeMode));
    }
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  void toggleTheme() {
    final newThemeMode =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    _preferences.setInt(_themeKey, newThemeMode.index);
    emit(ThemeState(newThemeMode));
  }

  void setThemeMode(ThemeMode themeMode) {
    _preferences.setInt(_themeKey, themeMode.index);
    emit(ThemeState(themeMode));
  }
}
