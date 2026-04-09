import 'package:bemyday/features/comments/models/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 댓글 API - Supabase comments 테이블 연동
class CommentRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 포스트의 댓글 목록 (created_at 오름차순)
  Future<List<Comment>> getComments(String postId) async {
    final rows = await _client
        .from('comments')
        .select('id, post_id, author_id, content, created_at')
        .eq('post_id', postId)
        .isFilter('deleted_at', null)
        .order('created_at');

    return (rows as List).map((r) => Comment.fromJson(r)).toList();
  }

  /// 댓글 작성
  Future<void> createComment(String postId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');
    await _client.from('comments').insert({
      'post_id': postId,
      'author_id': userId,
      'content': content.trim(),
    });
  }

  /// 댓글 삭제 (soft delete - deleted_at 설정)
  Future<void> deleteComment(String commentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');
    await _client.from('comments').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId).eq('author_id', userId);
  }

  /// 댓글 좋아요 수
  Future<int> getCommentLikeCount(String commentId) async {
    final res = await _client
        .from('comment_likes')
        .select('user_id')
        .eq('comment_id', commentId)
        .count(CountOption.exact);
    return res.count;
  }

  /// 댓글에 좋아요한 유저 ID 목록
  Future<List<String>> getCommentLikedUserIds(String commentId) async {
    final rows = await _client
        .from('comment_likes')
        .select('user_id')
        .eq('comment_id', commentId)
        .order('created_at');
    return (rows as List).map((r) => r['user_id'] as String).toList();
  }

  /// 현재 유저가 해당 댓글에 좋아요했는지 확인
  Future<bool> isCommentLikedByCurrentUser(String commentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final rows = await _client
        .from('comment_likes')
        .select('comment_id')
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  /// 댓글 좋아요 토글
  Future<bool> toggleCommentLike(String commentId, {bool? currentlyLiked}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final liked =
        currentlyLiked ?? await isCommentLikedByCurrentUser(commentId);
    if (liked) {
      await _client
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);
      return false;
    } else {
      await _client.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
      });
      return true;
    }
  }
}
