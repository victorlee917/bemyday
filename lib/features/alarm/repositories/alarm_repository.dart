import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 알람 설정 저장/불러오기
///
/// - Daily Reminder: 매일 오후 10시 정기 알림
/// - New Post: 소속 그룹에 새 포스트 (본인 제외)
/// - New Comment: 내 포스트에 새 댓글 (본인 제외)
/// - New Like: 내 포스트에 새 좋아요 (본인 제외)
///
/// SharedPreferences에 저장하고, 로그인 시 profiles 테이블에도 동기화하여
/// 백엔드 푸시 발송 로직에서 대상 유저 판별에 사용.
class AlarmRepository {
  static const _keyPrefix = 'alarm_';
  static const _keyDailyReminder = 'daily_reminder';
  static const _keyNewPost = 'new_post';
  static const _keyNewComment = 'new_comment';
  static const _keyNewLike = 'new_like';

  final SharedPreferences _prefs;

  AlarmRepository(this._prefs);

  String _key(String suffix) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return '$_keyPrefix${userId}_$suffix';
  }

  /// SharedPreferences에서만 로드 (동기, 오프라인용)
  AlarmPreferences loadFromLocal() {
    return AlarmPreferences(
      dailyReminder: _prefs.getBool(_key(_keyDailyReminder)) ?? false,
      newPost: _prefs.getBool(_key(_keyNewPost)) ?? false,
      newComment: _prefs.getBool(_key(_keyNewComment)) ?? false,
      newLike: _prefs.getBool(_key(_keyNewLike)) ?? false,
    );
  }

  /// DB(profiles) 우선 로드, 없으면 SharedPreferences 사용. DB 값이 있으면 로컬에 동기화.
  Future<AlarmPreferences> load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('alarm_daily_reminder, alarm_new_post, alarm_new_comment, alarm_new_like')
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          final prefs = AlarmPreferences(
            dailyReminder: res['alarm_daily_reminder'] as bool? ?? false,
            newPost: res['alarm_new_post'] as bool? ?? false,
            newComment: res['alarm_new_comment'] as bool? ?? false,
            newLike: res['alarm_new_like'] as bool? ?? false,
          );
          await _syncToLocal(prefs);
          return prefs;
        }
      } catch (_) {
        // 네트워크/권한 오류 시 로컬 폴백
      }
    }
    return loadFromLocal();
  }

  Future<void> _syncToLocal(AlarmPreferences prefs) async {
    await Future.wait([
      _prefs.setBool(_key(_keyDailyReminder), prefs.dailyReminder),
      _prefs.setBool(_key(_keyNewPost), prefs.newPost),
      _prefs.setBool(_key(_keyNewComment), prefs.newComment),
      _prefs.setBool(_key(_keyNewLike), prefs.newLike),
    ]);
  }

  Future<void> save(AlarmPreferences prefs) async {
    await _syncToLocal(prefs);

    // profiles에 동기화 (백엔드 푸시 발송 대상 판별용)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('profiles').update({
          'alarm_daily_reminder': prefs.dailyReminder,
          'alarm_new_post': prefs.newPost,
          'alarm_new_comment': prefs.newComment,
          'alarm_new_like': prefs.newLike,
        }).eq('id', userId);
      } catch (_) {
        // 마이그레이션 미적용 등으로 컬럼 없으면 무시
      }
    }
  }
}

class AlarmPreferences {
  const AlarmPreferences({
    this.dailyReminder = false,
    this.newPost = false,
    this.newComment = false,
    this.newLike = false,
  });

  final bool dailyReminder;
  final bool newPost;
  final bool newComment;
  final bool newLike;

  AlarmPreferences copyWith({
    bool? dailyReminder,
    bool? newPost,
    bool? newComment,
    bool? newLike,
  }) {
    return AlarmPreferences(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      newPost: newPost ?? this.newPost,
      newComment: newComment ?? this.newComment,
      newLike: newLike ?? this.newLike,
    );
  }
}
