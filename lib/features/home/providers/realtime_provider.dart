import 'dart:async';

import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 새 게시글/그룹/멤버 변경 시 HomeScreen, FriendsScreen 등 실시간 갱신
/// Supabase Realtime 구독 + 실패 시 재연결
final homeRealtimeProvider = Provider<void>((ref) {
  ref.watch(authStateProvider);
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return;

  void invalidateGroupProviders(String? groupId) {
    ref.invalidate(currentUserGroupsProvider);
    ref.invalidate(groupMemberCountProvider);
    ref.invalidate(groupMemberNicknamesProvider);
    ref.invalidate(groupMemberAvatarsProvider);
    ref.invalidate(groupDisplayNameProvider);
  }

  void invalidatePostProviders(String? groupId) {
    ref.invalidate(groupLatestPostsProvider);
    ref.invalidate(groupLatestRevealedPostsProvider);
    ref.invalidate(hasCurrentWeekPostsProvider);
    ref.invalidate(currentWeekPostsProvider);
    ref.invalidate(weekPostSummariesProvider);
  }

  void runOnMain(void Function() fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
  }

  Timer? retryTimer;
  RealtimeChannel? currentChannel;
  var disposed = false;
  var retryScheduled = false;
  var retryCount = 0;
  const retryDelay = Duration(seconds: 10);
  const maxRetries = 5;

  ref.onDispose(() {
    disposed = true;
    retryTimer?.cancel();
    if (currentChannel != null) {
      Supabase.instance.client.removeChannel(currentChannel!);
    }
  });

  void subscribeChannel() {
    if (disposed) return;
    retryScheduled = false;
    currentChannel = Supabase.instance.client
        .channel('home-updates')
        .onPostgresChanges(
          schema: 'public',
          table: 'posts',
          event: PostgresChangeEvent.all,
          callback: (payload) {
            final groupId = (payload.newRecord['group_id'] ??
                    payload.oldRecord['group_id']) as String?;
            if (kDebugMode) {
              debugPrint('Realtime: posts ${payload.eventType} group_id=$groupId');
            }
            runOnMain(() => invalidatePostProviders(groupId));
          },
        )
        .onPostgresChanges(
          schema: 'public',
          table: 'group_members',
          event: PostgresChangeEvent.all,
          callback: (payload) {
            final groupId = (payload.newRecord['group_id'] ??
                    payload.oldRecord['group_id']) as String?;
            runOnMain(() => invalidateGroupProviders(groupId));
          },
        )
        .onPostgresChanges(
          schema: 'public',
          table: 'groups',
          event: PostgresChangeEvent.insert,
          callback: (_) {
            runOnMain(() => ref.invalidate(currentUserGroupsProvider));
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            retryTimer?.cancel();
            retryCount = 0;
            if (kDebugMode) debugPrint('Realtime: subscribed');
            return;
          }
          if (disposed) return;
          if (retryScheduled) return;
          if (retryCount >= maxRetries) return;
          retryScheduled = true;
          retryCount++;
          if (kDebugMode) {
            debugPrint('Realtime: $status (retry $retryCount/$maxRetries)');
          }
          if (currentChannel != null) {
            Supabase.instance.client.removeChannel(currentChannel!);
          }
          currentChannel = null;
          retryTimer?.cancel();
          retryTimer = Timer(retryDelay, () {
            if (!disposed) subscribeChannel();
          });
        });
  }

  subscribeChannel();
});
