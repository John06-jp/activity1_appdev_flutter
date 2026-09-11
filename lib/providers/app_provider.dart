import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _userName = 'Alex Morgan';
  String _userRole = 'Lead Student Developer';
  String _studentId = '2024-10892';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get userName => _userName;
  String get userRole => _userRole;
  String get studentId => _studentId;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void updateProfile({required String name, required String role, required String studentId}) {
    _userName = name.trim().isEmpty ? 'Student Developer' : name.trim();
    _userRole = role.trim().isEmpty ? 'App Development Student' : role.trim();
    _studentId = studentId.trim().isEmpty ? 'N/A' : studentId.trim();
    notifyListeners();
  }
}
