import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/alarm/repositories/alarm_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
