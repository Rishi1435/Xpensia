import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _profileImagePath;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String? get profileImagePath => _profileImagePath;

  ThemeProvider() {
    _loadFromPrefs();
  }

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _profileImagePath = prefs.getString('profileImagePath');
    _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    notifyListeners();
  }

  Future<void> toggleBiometric(bool isEnabled) async {
    _isBiometricEnabled = isEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricEnabled', isEnabled);
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> setProfileImage(String path) async {
    _profileImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
  }
}
