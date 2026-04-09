import 'package:flutter/material.dart';
import 'package:bemyday/features/comments/providers/comment_provider.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/models/post_with_details.dart';
import 'package:bemyday/features/post/widgets/comment_nudge_banner.dart';
import 'package:bemyday/features/post/widgets/post_bottom_bar.dart';
import 'package:bemyday/features/post/widgets/post_nudge_banner.dart';
import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 포스트 하단 섹션: 넛지 배너 + PostBottomBar
class PostBottomSection extends ConsumerWidget {
  const PostBottomSection({
    super.key,
    required this.post,
    required this.authorProfileAsync,
    required this.detailsAsync,
    required this.shouldBlur,
    required this.authorPostIndex,
    required this.authorPostCount,
    required this.likeOverride,
    required this.likeCountOverride,
    required this.dismissedCommentIdByPost,
    required this.onCommentNudgeDismiss,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onPostTap,
    this.onCaptionTap,
  });

  final Post post;
  final AsyncValue<Profile?> authorProfileAsync;
  final AsyncValue<PostWithDetails> detailsAsync;
  final bool shouldBlur;
  final int authorPostIndex;
  final int authorPostCount;
  final bool? likeOverride;
  final int? likeCountOverride;
  final Map<String, String> dismissedCommentIdByPost;
  final void Function(String postId, String commentId) onCommentNudgeDismiss;
  final void Function(Post post, bool currentlyLiked, int currentCount) onLikeTap;
  final void Function(Post post, {bool autofocus, String? scrollToCommentId})
      onCommentTap;
  final VoidCallback onPostTap;
  final VoidCallback? onCaptionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedNickname = authorProfileAsync.valueOrNull?.nickname ?? '';
    final cachedAvatarUrl = authorProfileAsync.valueOrNull?.avatarUrl;

    if (shouldBlur) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cachedNickname.isNotEmpty)
            PostNudgeBanner(nickname: cachedNickname, onTap: onPostTap),
          PostBottomBar(
            nickname:
                detailsAsync.valueOrNull?.authorNickname ?? cachedNickname,
            avatarUrl:
                detailsAsync.valueOrNull?.authorAvatarUrl ?? cachedAvatarUrl,
            date: formatTimeAgo(post.createdAt, context),
            postIndex: authorPostIndex,
            postCount: authorPostCount,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            hideLikeComment: true,
          ),
        ],
      );
    }

    final d = detailsAsync.valueOrNull;
    final commentsAsync = d != null && d.commentCount > 0
        ? ref.watch(commentsProvider(post.id))
        : null;
    final latestComment = commentsAsync?.valueOrNull?.isNotEmpty == true
        ? commentsAsync!.value!.last
        : null;
    final isBannerDismissed =
        latestComment != null &&
        dismissedCommentIdByPost[post.id] == latestComment.id;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnComment =
        latestComment != null && latestComment.authorId == currentUserId;

    return Column(
      children: [
        if (latestComment != null && !isBannerDismissed && !isOwnComment)
          CommentNudgeBanner(
            comment: latestComment,
            onTap: () {
              onCommentNudgeDismiss(post.id, latestComment.id);
              onCommentTap(
                post,
                autofocus: false,
                scrollToCommentId: latestComment.id,
              );
            },
          ),
        PostBottomBar(
          nickname: d?.authorNickname ?? cachedNickname,
          avatarUrl: d?.authorAvatarUrl ?? cachedAvatarUrl,
          date: formatTimeAgo(post.createdAt, context),
          likeCount: likeCountOverride ?? d?.likeCount ?? 0,
          commentCount: d?.commentCount ?? 0,
          isLiked: likeOverride ?? d?.isLiked ?? false,
          likedUserIds: d?.likedUserIds ?? [],
          caption: post.caption,
          isOwnPost: post.authorId == currentUserId,
          postIndex: authorPostIndex,
          postCount: authorPostCount,
          onLikeTap: () => onLikeTap(
            post,
            likeOverride ?? d?.isLiked ?? false,
            likeCountOverride ?? d?.likeCount ?? 0,
          ),
          onCommentTap: () => onCommentTap(post, autofocus: true),
          onAvatarTap: post.authorId != currentUserId
              ? () => onCommentTap(post, autofocus: false)
              : onCaptionTap,
          onCaptionTap: onCaptionTap,
        ),
      ],
    );
  }
}
