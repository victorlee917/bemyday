import 'package:bemyday/features/comments/models/comment.dart';
import 'package:bemyday/features/comments/repositories/comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

/// 포스트의 댓글 목록 (오래된 댓글일수록 위에)
final commentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) async {
  final comments =
      await ref.read(commentRepositoryProvider).getComments(postId);
  comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return comments;
});

/// 댓글별 좋아요 상태 (likeCount, isLiked, likedUserIds)
final commentLikeProvider =
    FutureProvider.family<({int likeCount, bool isLiked, List<String> likedUserIds}), String>(
        (ref, commentId) async {
  final repo = ref.read(commentRepositoryProvider);
  final results = await Future.wait([
    repo.getCommentLikeCount(commentId),
    repo.isCommentLikedByCurrentUser(commentId),
    repo.getCommentLikedUserIds(commentId),
  ]);
  return (
    likeCount: results[0] as int,
    isLiked: results[1] as bool,
    likedUserIds: results[2] as List<String>,
  );
});
