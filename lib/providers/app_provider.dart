import 'package:flutter/material.dart';

enum AppAccentColor {
  blue('Blue', Color(0xFF3B6FE8)),
  green('Green', Color(0xFF2E8B57)),
  orange('Orange', Color(0xFFE87524)),
  purple('Purple', Color(0xFF7B4BC4));

  const AppAccentColor(this.label, this.primary);

  final String label;
  final Color primary;
}

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _userName = 'Jansey Sa-a';
  String _userRole = 'Student';
  String _studentId = '2024-0001';
  AppAccentColor _accentColor = AppAccentColor.blue;
  int _avatarIndex = 0;

  static const List<IconData> avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.school,
    Icons.code,
  ];

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get userName => _userName;
  String get userRole => _userRole;
  String get studentId => _studentId;
  AppAccentColor get accentColor => _accentColor;
  int get avatarIndex => _avatarIndex;
  IconData get currentAvatarIcon => avatarIcons[_avatarIndex];

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
    String? studentId,
  }) {
    _userName = name.trim().isEmpty ? 'Student' : name.trim();
    _userRole = role.trim().isEmpty ? 'Student' : role.trim();
    if (studentId != null) {
      _studentId = studentId.trim().isEmpty ? 'Not set' : studentId.trim();
    }
    notifyListeners();
  }

  void setAccentColor(AppAccentColor color) {
    _accentColor = color;
    notifyListeners();
  }

  void setAvatarIndex(int index) {
    if (index < 0 || index >= avatarIcons.length) return;
    _avatarIndex = index;
    notifyListeners();
  }
}
