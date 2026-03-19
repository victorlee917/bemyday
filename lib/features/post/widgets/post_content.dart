import 'dart:io';
import 'dart:ui';

import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/common/widgets/gradient_overlay.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/features/post/widgets/post_bottom_section.dart';
import 'package:bemyday/features/post/widgets/post_header_bar.dart';
import 'package:bemyday/features/post/widgets/reveal_countdown.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 포스트 상세 뷰: 이미지, 오버레이, 헤더, 하단 바
class PostContent extends ConsumerWidget {
  const PostContent({
    super.key,
    required this.group,
    required this.post,
    required this.allPosts,
    required this.currentIndex,
    required this.weekIndex,
    required this.dragOffset,
    required this.likeOverride,
    required this.likeCountOverride,
    required this.dismissedCommentIdByPost,
    required this.onTapUp,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onCloseTap,
    required this.onMoreTap,
    required this.onPostTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onCommentNudgeDismiss,
  });

  final Group group;
  final Post post;
  final List<Post> allPosts;
  final int currentIndex;
  final int? weekIndex;
  final double dragOffset;
  final bool? likeOverride;
  final int? likeCountOverride;
  final Map<String, String> dismissedCommentIdByPost;
  final void Function(TapUpDetails details, int itemCount) onTapUp;
  final void Function(DragUpdateDetails details) onVerticalDragUpdate;
  final void Function(DragEndDetails details) onVerticalDragEnd;
  final VoidCallback onCloseTap;
  final void Function(Post post) onMoreTap;
  final VoidCallback? onPostTap;
  final void Function(Post post, bool currentlyLiked, int currentCount)
  onLikeTap;
  final void Function(Post post, {bool autofocus, String? scrollToCommentId})
  onCommentTap;
  final void Function(String postId, String commentId) onCommentNudgeDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorProfileAsync = ref.watch(profileProvider(post.authorId));
    final detailsAsync = ref.watch(postWithDetailsProvider(post));
    final weekdayIndex = group.weekday - 1;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnPost = post.authorId == currentUserId;
    final beforeReveal = isCurrentWeekBeforeReveal(
      group,
      viewingWeekIndex: weekIndex,
    );
    final shouldBlur = beforeReveal && !isOwnPost;
    final itemCount = allPosts.length;

    final authorPosts = allPosts
        .where((p) => p.authorId == post.authorId)
        .toList();
    final authorPostIndex = authorPosts.indexOf(post) + 1;
    final authorPostCount = authorPosts.length;

    final screenHeight = MediaQuery.of(context).size.height;
    final opacity = (1 - (dragOffset / screenHeight) * 1.5).clamp(0.0, 1.0);
    final isDragging = dragOffset > 0;
    final borderRadius = isDragging
        ? BorderRadius.vertical(top: Radius.circular(16))
        : BorderRadius.zero;

    return GestureDetector(
      onTapUp: (d) => onTapUp(d, itemCount),
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: opacity),
        child: Transform.translate(
          offset: Offset(0, dragOffset),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: shouldBlur
                        ? Blurs.fullScreen
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: CachedPostImage(
                      imageUrl: post.photoUrl,
                      cacheKey: post.storagePath,
                      errorWidget: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Container(
                            color: Colors.black,
                            child: Center(
                              child: Text(
                                l10n.postFailedToLoad,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                GradientOverlay(
                  height: MediaQuery.of(context).padding.top + 120,
                  alignment: Alignment.topCenter,
                  opacity: 0.55,
                ),
                GradientOverlay(
                  height: 200,
                  alignment: Alignment.bottomCenter,
                  opacity: 0.55,
                ),
                if (shouldBlur)
                  Center(child: RevealCountdown(targetWeekday: group.weekday)),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PostHeaderBar(
                    weekdayName: weekdays[weekdayIndex].name,
                    weekNumber: groupWeekNumber(group),
                    currentIndex: currentIndex,
                    itemCount: itemCount,
                    onCloseTap: onCloseTap,
                    onMoreTap: isOwnPost ? () => onMoreTap(post) : null,
                    onPostTap:
                        weekIndex == null || weekIndex == groupWeekNumber(group)
                        ? onPostTap
                        : null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: Platform.isAndroid ? Paddings.scaffoldV : 0,
                      ),
                      child: PostBottomSection(
                        post: post,
                        authorProfileAsync: authorProfileAsync,
                        detailsAsync: detailsAsync,
                        shouldBlur: shouldBlur,
                        authorPostIndex: authorPostIndex,
                        authorPostCount: authorPostCount,
                        likeOverride: likeOverride,
                        likeCountOverride: likeCountOverride,
                        dismissedCommentIdByPost: dismissedCommentIdByPost,
                        onCommentNudgeDismiss: onCommentNudgeDismiss,
                        onLikeTap: onLikeTap,
                        onCommentTap: onCommentTap,
                        onPostTap: onPostTap ?? () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
