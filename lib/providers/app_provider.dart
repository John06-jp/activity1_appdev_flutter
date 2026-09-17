import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _userName = 'Jansey Sa-a';
  String _userRole = 'Student';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get userName => _userName;
  String get userRole => _userRole;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String role,
  }) {
    _userName = name.trim().isEmpty ? 'Student' : name.trim();
    _userRole = role.trim().isEmpty ? 'Student' : role.trim();
    notifyListeners();
  }
}
