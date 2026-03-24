import 'dart:async';

import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/models/post_with_details.dart';
import 'package:bemyday/features/post/repositories/post_repository.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 포스트 간 전환 시 상세를 잠시 재사용; 마지막 구독 해제 후 이 시간이 지나면 메모리에서 비움.
const _postDetailsListenAwayCache = Duration(seconds: 45);

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

/// 현재 week에 해당하는 포스트 존재 여부
final hasCurrentWeekPostsProvider =
    FutureProvider.family<bool, Group>((ref, group) async {
  return ref.read(postRepositoryProvider).hasCurrentWeekPosts(group);
});

/// 현재 week에 해당하는 포스트 목록
final currentWeekPostsProvider =
    FutureProvider.family<List<Post>, Group>((ref, group) async {
  return ref.read(postRepositoryProvider).getCurrentWeekPosts(group);
});

/// 그룹의 최신 포스트 최대 4개 (Friends 화면용)
final groupLatestPostsProvider =
    FutureProvider.family<List<Post>, Group>((ref, group) async {
  return ref.read(postRepositoryProvider).getLatestPosts(group, limit: 4);
});

/// 그룹의 최신 공개된 포스트 최대 4개 (Friends 화면용)
/// blur 해제된 사진만 표시. 공개된 포스트가 없으면 빈 목록.
final groupLatestRevealedPostsProvider =
    FutureProvider.family<List<Post>, Group>((ref, group) async {
  final posts = await ref.read(postRepositoryProvider).getLatestPosts(
        group,
        limit: 20,
      );
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final revealed = posts
      .where((p) => isPostRevealed(p, group, currentUserId))
      .take(4)
      .toList();
  return revealed;
});

/// 특정 week에 해당하는 포스트 목록
final weekPostsProvider = FutureProvider.family<List<Post>,
    ({Group group, int weekIndex})>((ref, params) async {
  return ref
      .read(postRepositoryProvider)
      .getPostsByWeek(params.group, params.weekIndex);
});

/// 그룹의 주별 포스트 요약 (PartyScreen 그리드용)
final weekPostSummariesProvider = FutureProvider.family<
    List<({int weekIndex, int postCount, List<String> authorIds, Post? latestPost})>,
    Group>((ref, group) async {
  return ref.read(postRepositoryProvider).getWeekPostSummaries(group);
});

/// 포스트 상세 (작성자 닉네임, 좋아요/댓글 수, 좋아요한 유저 닉네임)
final postWithDetailsProvider =
    FutureProvider.autoDispose.family<PostWithDetails, Post>((ref, post) async {
  final link = ref.keepAlive();
  Timer? releaseTimer;

  ref.onCancel(() {
    releaseTimer?.cancel();
    releaseTimer = Timer(_postDetailsListenAwayCache, link.close);
  });

  ref.onResume(() {
    releaseTimer?.cancel();
  });

  ref.onDispose(() {
    releaseTimer?.cancel();
  });

  final repo = ref.read(postRepositoryProvider);

  final authorProfile =
      await ref.watch(profileProvider(post.authorId).future);

  final results = await Future.wait([
    repo.getPostLikeCount(post.id),
    repo.getPostCommentCount(post.id),
    repo.getPostLikedUserIds(post.id),
    repo.isPostLikedByCurrentUser(post.id),
  ]);

  final likeCount = results[0] as int;
  final commentCount = results[1] as int;
  final likedIds = results[2] as List<String>;
  final isLiked = results[3] as bool;

  return PostWithDetails(
    post: post,
    authorNickname: authorProfile?.nickname ?? '?',
    authorAvatarUrl: authorProfile?.avatarUrl,
    likeCount: likeCount,
    commentCount: commentCount,
    likedUserIds: likedIds,
    isLiked: isLiked,
  );
});
