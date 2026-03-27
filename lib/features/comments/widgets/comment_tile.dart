import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/comments/providers/comment_provider.dart';
import 'package:bemyday/features/comments/widgets/comment_mention_text_spans.dart';
import 'package:bemyday/features/post/widgets/likes_sheet.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    super.key,
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.onCommentDeleted,
  });

  final String commentId;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final VoidCallback? onCommentDeleted;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  int? _likeCountOverride;
  bool? _isLikedOverride;

  Future<void> _onLikeTap() async {
    final likeAsync = ref.read(commentLikeProvider(widget.commentId));
    final current = likeAsync.valueOrNull;
    if (current == null) return;

    final newLiked = !current.isLiked;
    final newCount = current.likeCount + (newLiked ? 1 : -1);

    setState(() {
      _isLikedOverride = newLiked;
      _likeCountOverride = newCount.clamp(0, 0x7FFFFFFF);
    });

    try {
      await ref.read(commentRepositoryProvider).toggleCommentLike(
            widget.commentId,
            currentlyLiked: current.isLiked,
          );
      ref.invalidate(commentLikeProvider(widget.commentId));
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLikedOverride = null;
          _likeCountOverride = null;
        });
      }
    }
  }

  void _onLikeLongPress() {
    final likeAsync = ref.read(commentLikeProvider(widget.commentId));
    final current = likeAsync.valueOrNull;
    if (current == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    List<String> likedUserIds;
    if (_isLikedOverride != null && currentUserId != null) {
      if (_isLikedOverride!) {
        likedUserIds = current.likedUserIds.contains(currentUserId)
            ? current.likedUserIds
            : [...current.likedUserIds, currentUserId];
      } else {
        likedUserIds =
            current.likedUserIds.where((id) => id != currentUserId).toList();
      }
    } else {
      likedUserIds = current.likedUserIds;
    }

    if (likedUserIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) =>
            LikesSheet(likedUserIds: likedUserIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnComment =
        currentUserId != null && widget.authorId == currentUserId;
    final likeAsync = ref.watch(commentLikeProvider(widget.commentId));

    final profileAsync = ref.watch(profileProvider(widget.authorId));
    return profileAsync.when(
      data: (profile) {
        final nickname = profile?.nickname ?? '?';
        final isLiked = _isLikedOverride ?? likeAsync.valueOrNull?.isLiked ?? false;
        final likeCount =
            _likeCountOverride ?? likeAsync.valueOrNull?.likeCount ?? 0;

        final likeWidget = GestureDetector(
          onTap: likeAsync.valueOrNull != null ? _onLikeTap : null,
          onLongPress:
              likeCount > 0 ? _onLikeLongPress : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                size: Sizes.size16,
                color: isLiked ? Colors.redAccent : null,
              ),
              if (likeCount > 0) ...[
                Gaps.v6,
                Text(
                  '$likeCount',
                  style: TextStyle(fontSize: Sizes.size10),
                ),
              ],
            ],
          ),
        );

        final tile = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Sizes.size12,
          ),
          child: Row(
            children: [
              AvatarDefault(
                nickname: nickname,
                avatarUrl: profile?.avatarUrl,
                radius: CustomSizes.avatarComment,
              ),
              CustomSizes.commentLeadingGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nickname,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CustomSizes.commentDateGap,
                        Opacity(
                          opacity: 0.3,
                          child: Text(
                            formatTimeAgo(widget.createdAt, context),
                            style: TextStyle(fontSize: Sizes.size10),
                          ),
                        ),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        children: commentMentionTextSpans(
                          widget.content,
                          TextStyle(fontSize: Sizes.size12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CustomSizes.commentTrailingGap,
              likeWidget,
            ],
          ),
        );

        if (isOwnComment) {
          return Dismissible(
            key: ValueKey(widget.commentId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: Sizes.size24),
              color: CustomColors.destructiveColorDark,
              child: FaIcon(
                FontAwesomeIcons.trash,
                color: Colors.white,
                size: Sizes.size20,
              ),
            ),
            confirmDismiss: (direction) async {
              try {
                await ref
                    .read(commentRepositoryProvider)
                    .deleteComment(widget.commentId);
                ref.invalidate(commentsProvider(widget.postId));
                widget.onCommentDeleted?.call();
                return true;
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, '삭제에 실패했습니다.');
                }
                return false;
              }
            },
            child: tile,
          );
        }

        return tile;
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }
}
