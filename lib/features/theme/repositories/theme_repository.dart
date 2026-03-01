import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [Model] 테마 데이터 저장/불러오기를 담당하는 Repository
///
/// MVVM에서 Model 역할:
/// - 데이터 소스(SharedPreferences)와 직접 통신
/// - 순수한 데이터 CRUD 로직만 담당
/// - UI나 상태 관리에 대해 모름
class ThemeRepository {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeRepository(this._prefs);

  /// 저장된 테마 모드를 불러옴
  ThemeMode load() {
    final savedTheme = _prefs.getString(_key) ?? 'device';
    return _stringToThemeMode(savedTheme);
  }

  /// 테마 모드를 저장
  Future<void> save(String mode) async {
    await _prefs.setString(_key, mode);
  }

  /// 문자열 -> ThemeMode 변환
  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
