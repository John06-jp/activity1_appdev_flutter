import 'package:flutter/material.dart';

enum AppAccentColor {
  indigo('Deep Violet', Colors.deepPurple, Colors.indigoAccent),
  ocean('Ocean Breeze', Colors.blue, Colors.tealAccent),
  emerald('Emerald Forest', Colors.teal, Color(0xFF10B981)),
  rose('Cyber Rose', Colors.pink, Color(0xFFF43F5E));

  final String label;
  final Color primary;
  final Color accent;

  const AppAccentColor(this.label, this.primary, this.accent);
}

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  AppAccentColor _accentColor = AppAccentColor.indigo;
  String _userName = 'Alex Morgan';
  String _userRole = 'Lead Student Developer';
  String _studentId = '2024-10892';
  int _avatarIndex = 0;

  // Avatar icon options
  static const List<IconData> avatarIcons = [
    Icons.person_rounded,
    Icons.terminal_rounded,
    Icons.code_rounded,
    Icons.rocket_launch_rounded,
    Icons.psychology_rounded,
  ];

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppAccentColor get accentColor => _accentColor;
  String get userName => _userName;
  String get userRole => _userRole;
  String get studentId => _studentId;
  int get avatarIndex => _avatarIndex;
  IconData get currentAvatarIcon => avatarIcons[_avatarIndex % avatarIcons.length];

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(AppAccentColor color) {
    _accentColor = color;
    notifyListeners();
  }

  void setAvatarIndex(int index) {
    _avatarIndex = index;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String role,
    required String studentId,
  }) {
    _userName = name.trim().isEmpty ? 'Student Developer' : name.trim();
    _userRole = role.trim().isEmpty ? 'App Development Student' : role.trim();
    _studentId = studentId.trim().isEmpty ? 'N/A' : studentId.trim();
    notifyListeners();
  }
}
