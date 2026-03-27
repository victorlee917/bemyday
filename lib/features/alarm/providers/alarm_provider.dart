import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/alarm/repositories/alarm_repository.dart';
import 'package:bemyday/features/push/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 시스템 알림 권한 상태. denied이면 설정에서 꺼진 상태.
final notificationPermissionProvider =
    FutureProvider<AuthorizationStatus>((ref) async {
  final settings =
      await FirebaseMessaging.instance.getNotificationSettings();
  return settings.authorizationStatus;
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AlarmRepository(prefs);
});

final alarmPreferencesProvider =
    AsyncNotifierProvider<AlarmPreferencesNotifier, AlarmPreferences>(
  AlarmPreferencesNotifier.new,
);

class AlarmPreferencesNotifier extends AsyncNotifier<AlarmPreferences> {
  AlarmRepository get _repository => ref.read(alarmRepositoryProvider);

  @override
  Future<AlarmPreferences> build() => _repository.load();

  Future<void> setDailyReminder(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(dailyReminder: value));
    await _repository.save(state.value!);
    await PushNotificationService.syncDailyReminder(value);
  }

  Future<void> setNewPost(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(newPost: value));
    await _repository.save(state.value!);
  }

  Future<void> setNewComment(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(newComment: value));
    await _repository.save(state.value!);
  }

  Future<void> setNewLike(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(newLike: value));
    await _repository.save(state.value!);
  }

  Future<void> setCommentMention(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(commentMention: value));
    await _repository.save(state.value!);
  }

  /// 푸시 권한 동의 시 모든 알람 ON
  Future<void> enableAll() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final allOn = current.copyWith(
      dailyReminder: true,
      newPost: true,
      newComment: true,
      newLike: true,
      commentMention: true,
    );
    if (current.dailyReminder &&
        current.newPost &&
        current.newComment &&
        current.newLike &&
        current.commentMention) {
      return;
    }
    state = AsyncData(allOn);
    await _repository.save(allOn);
    await PushNotificationService.syncDailyReminder(true);
  }
}
