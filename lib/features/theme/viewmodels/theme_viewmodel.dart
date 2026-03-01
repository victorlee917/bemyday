import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/theme/repositories/theme_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ViewModel] 테마 상태 관리 및 비즈니스 로직 담당
///
/// MVVM에서 ViewModel 역할:
/// - View와 Model(Repository) 사이의 중재자
/// - UI에 필요한 상태를 보관하고 노출
/// - UI 이벤트를 받아 Repository에 전달
/// - Riverpod Notifier로 상태 변경 시 View에 자동 알림
class ThemeViewModel extends Notifier<ThemeMode> {
  /// Repository 접근 (ref를 통해 주입받음)
  ThemeRepository get _repository => ref.read(themeRepositoryProvider);

  @override
  ThemeMode build() {
    // Repository에서 저장된 테마 불러오기
    return _repository.load();
  }

  /// 테마 모드를 문자열로 반환 (UI 표시용)
  String get themeModeString {
    switch (state) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'device';
    }
  }

  /// 테마 변경 요청 (View에서 호출)
  ///
  /// 1. 상태 업데이트 -> View 자동 리빌드
  /// 2. Repository에 저장 요청
  Future<void> setThemeMode(String mode) async {
    state = _stringToThemeMode(mode);
    await _repository.save(mode);
  }

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

/// ViewModel Provider
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeMode>(() => ThemeViewModel());

/// Repository Provider
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeRepository(prefs);
});
