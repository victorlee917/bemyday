import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/language/repositories/language_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ViewModel] 테마 상태 관리 및 비즈니스 로직 담당
///
/// MVVM에서 ViewModel 역할:
/// - View와 Model(Repository) 사이의 중재자
/// - UI에 필요한 상태를 보관하고 노출
/// - UI 이벤트를 받아 Repository에 전달
/// - Riverpod Notifier로 상태 변경 시 View에 자동 알림
class LanguageViewModel extends Notifier<String> {
  /// Repository 접근 (ref를 통해 주입받음)
  LanguageRepository get _repository => ref.read(languageRepositoryProvider);

  @override
  String build() {
    // Repository에서 저장된 언어 불러오기
    return _repository.load();
  }

  /// 현재 언어 값 반환 (View에서 사용)
  String get currentLanguage => state;

  /// 언어 변경 요청 (View에서 호출)
  ///
  /// 1. 상태 업데이트 -> View 자동 리빌드
  /// 2. Repository에 저장 요청
  Future<void> setLanguage(String language) async {
    state = language;
    await _repository.save(language);
  }
}

/// ViewModel Provider
final languageViewModelProvider = NotifierProvider<LanguageViewModel, String>(
  () => LanguageViewModel(),
);

/// Repository Provider
final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageRepository(prefs);
});
