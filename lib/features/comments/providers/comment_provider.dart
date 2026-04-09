import 'package:bemyday/features/comments/models/comment.dart';
import 'package:bemyday/features/comments/repositories/comment_repository.dart';
import 'package:bemyday/features/report/providers/report_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

/// 포스트의 댓글 목록 (오래된 댓글일수록 위에, 차단 사용자 제외)
final commentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) async {
  final comments =
      await ref.read(commentRepositoryProvider).getComments(postId);
  final blockedIds = await ref.watch(blockedUserIdsProvider.future);
  final filtered = blockedIds.isEmpty
      ? comments
      : comments.where((c) => !blockedIds.contains(c.authorId)).toList();
  filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return filtered;
});

/// 댓글별 좋아요 상태 (likeCount, isLiked, likedUserIds)
final commentLikeProvider =
    FutureProvider.family<({int likeCount, bool isLiked, List<String> likedUserIds}), String>(
        (ref, commentId) async {
  final repo = ref.read(commentRepositoryProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final likedUserIds = await repo.getCommentLikedUserIds(commentId);
  return (
    likeCount: likedUserIds.length,
    isLiked: currentUserId != null && likedUserIds.contains(currentUserId),
    likedUserIds: likedUserIds,
  );
});
