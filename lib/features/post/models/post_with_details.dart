import 'package:bemyday/features/post/models/post.dart';

/// 포스트 + 작성자/좋아요/댓글 메타데이터
class PostWithDetails {
  const PostWithDetails({
    required this.post,
    required this.authorNickname,
    this.authorAvatarUrl,
    required this.likeCount,
    required this.commentCount,
    required this.likedUserIds,
    required this.isLiked,
  });

  final Post post;
  final String authorNickname;
  final String? authorAvatarUrl;
  final int likeCount;
  final int commentCount;
  final List<String> likedUserIds;
  final bool isLiked;
}
