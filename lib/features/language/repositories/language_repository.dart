import 'package:shared_preferences/shared_preferences.dart';

/// [Model] 언어 설정 저장/불러오기를 담당하는 Repository
///
/// MVVM에서 Model 역할:
/// - 데이터 소스(SharedPreferences)와 직접 통신
/// - 순수한 데이터 CRUD 로직만 담당
/// - UI나 상태 관리에 대해 모름
class LanguageRepository {
  static const _key = 'language';
  final SharedPreferences _prefs;

  LanguageRepository(this._prefs);

  /// 저장된 언어 설정을 불러옴
  String load() {
    final String savedLanguage = _prefs.getString(_key) ?? 'en';
    return savedLanguage;
  }

  /// 언어 설정을 저장
  Future<void> save(String language) async {
    await _prefs.setString(_key, language);
  }
}
