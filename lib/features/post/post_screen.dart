import 'package:bemyday/common/widgets/confirm_dialog.dart';
import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/common/widgets/gradient_overlay.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/comments/comments_sheet.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/models/post_with_details.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/post/widgets/post_bottom_bar.dart';
import 'package:bemyday/features/post/widgets/post_header_bar.dart';
import 'package:bemyday/features/comments/providers/comment_provider.dart';
import 'package:bemyday/features/post/widgets/comment_nudge_banner.dart';
import 'package:bemyday/features/post/widgets/post_nudge_banner.dart';
import 'package:bemyday/features/post/widgets/reveal_countdown.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    super.key,
    this.group,
    this.weekIndex,
    this.startFromLatest = false,
  });

  static const routeName = "post";
  static const routeUrl = "/post";

  final Group? group;
  final int? weekIndex;
  final bool startFromLatest;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen>
    with SingleTickerProviderStateMixin {
  int? _currentIndex;
  bool _userNavigated = false;
  bool? _likeOverride;
  int? _likeCountOverride;

  /// 넛지 배너 탭 시 해당 댓글은 더 이상 표시하지 않음 (postId -> commentId)
  final Map<String, String> _dismissedCommentIdByPost = {};

  double _dragOffset = 0;
  late final AnimationController _dragAnimController;

  @override
  void initState() {
    super.initState();
    _dragAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  bool _hasScheduledPop = false;

  @override
  void dispose() {
    _dragAnimController
      ..removeListener(_dismissListener)
      ..removeListener(_snapBackListener)
      ..dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dy).clamp(
          0,
          double.infinity,
        );
      });
    }
  }

  bool _isDismissing = false;

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > screenHeight * 0.2 || velocity > 800) {
      _dismissWithAnimation(screenHeight);
    } else {
      _snapBack();
    }
  }

  void _dismissWithAnimation(double screenHeight) {
    if (_isDismissing) return;
    _isDismissing = true;
    final start = _dragOffset;
    final remaining = screenHeight - start;
    _dragAnimController.reset();
    _dragAnimController.removeListener(_snapBackListener);
    _dragAnimController.addListener(
      _dismissListener = () {
        setState(() {
          _dragOffset = start + remaining * _dragAnimController.value;
        });
      },
    );
    _dragAnimController.forward().then((_) {
      if (mounted) context.pop();
    });
  }

  void _snapBack() {
    final start = _dragOffset;
    _dragAnimController.reset();
    _dragAnimController.removeListener(_dismissListener);
    _dragAnimController.addListener(
      _snapBackListener = () {
        setState(() {
          _dragOffset = start * (1 - _dragAnimController.value);
        });
      },
    );
    _dragAnimController.forward();
  }

  VoidCallback _dismissListener = () {};
  VoidCallback _snapBackListener = () {};

  void _onTapUp(TapUpDetails details, int itemCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final idx = _currentIndex ?? 0;
    if (tapX < screenWidth / 2) {
      if (idx > 0) {
        _userNavigated = true;
        setState(() {
          _currentIndex = idx - 1;
          _likeOverride = null;
          _likeCountOverride = null;
        });
      }
    } else {
      if (idx < itemCount - 1) {
        _userNavigated = true;
        setState(() {
          _currentIndex = idx + 1;
          _likeOverride = null;
          _likeCountOverride = null;
        });
      }
    }
  }

  void _precacheAdjacentImages(List<Post> posts, int current) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final offset in [1, -1, 2, -2]) {
        final i = current + offset;
        if (i < 0 || i >= posts.length) continue;
        final p = posts[i];
        precacheImage(
          CachedNetworkImageProvider(p.photoUrl, cacheKey: p.storagePath),
          context,
        );
      }
    });
  }

  static const _sheetInitialSize = 0.8;
  static const _sheetMinSize = 0.5; // threshold: below this = dismiss

  void _onCommentsTap(
    BuildContext context,
    Post post, {
    bool autofocus = true,
    String? scrollToCommentId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: _sheetInitialSize,
        minChildSize: _sheetMinSize,
        maxChildSize: _sheetInitialSize,
        snap: true,
        snapSizes: const [_sheetMinSize, _sheetInitialSize],
        shouldCloseOnMinExtent: true,
        expand: false,
        builder: (context, scrollController) => CommentsSheet(
          postId: post.id,
          autofocus: autofocus,
          scrollController: scrollController,
          scrollToCommentId: scrollToCommentId,
          onCommentAdded: () => ref.invalidate(postWithDetailsProvider(post)),
        ),
      ),
    );
  }

  void _onCloseTap() {
    context.pop();
  }

  void _onPostTap() async {
    final group = widget.group;
    final weekdayIndex = group != null ? (group.weekday - 1) : 0;
    final result = await context.push(
      PostingAlbumScreen.routeUrl,
      extra: weekdayIndex,
    );
    if (result is Group && mounted) {
      ref.invalidate(currentWeekPostsProvider(result));
      ref.invalidate(hasCurrentWeekPostsProvider(result));
      ref.invalidate(weekPostSummariesProvider(result));
      ref.invalidate(currentUserGroupsProvider);
      context.pushReplacement(
        PostScreen.routeUrl,
        extra: {'group': result, 'startFromLatest': true},
      );
    }
  }

  void _onMoreTap(Post post) async {
    bool deleteRequested = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SheetSelect(
        items: [
          SheetItem(
            title: "Delete Post",
            onTap: () => deleteRequested = true,
            isDestructive: true,
          ),
        ],
      ),
    );
    if (deleteRequested && mounted) {
      _confirmDelete(post);
    }
  }

  void _confirmDelete(Post post) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      _deletePost(post);
    }
  }

  Future<void> _deletePost(Post post) async {
    await ref.read(postRepositoryProvider).deletePost(post.id);
    ref.invalidate(hasCurrentWeekPostsProvider(widget.group!));
    ref.invalidate(currentWeekPostsProvider(widget.group!));
    ref.invalidate(weekPostSummariesProvider(widget.group!));
    ref.invalidate(currentUserGroupsProvider);
    if (widget.weekIndex != null) {
      ref.invalidate(
        weekPostsProvider((group: widget.group!, weekIndex: widget.weekIndex!)),
      );
    }
  }

  Future<void> _onLikeTap(
    Post post,
    bool currentlyLiked,
    int currentCount,
  ) async {
    setState(() {
      _likeOverride = !currentlyLiked;
      _likeCountOverride = currentlyLiked ? currentCount - 1 : currentCount + 1;
    });

    await ref
        .read(postRepositoryProvider)
        .toggleLike(post.id, currentlyLiked: currentlyLiked);
    ref.invalidate(postWithDetailsProvider(post));
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    if (group == null) {
      return Scaffold(
        body: Center(
          child: Text("No group", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final postsAsync = widget.weekIndex != null
        ? ref.watch(
            weekPostsProvider((group: group, weekIndex: widget.weekIndex!)),
          )
        : ref.watch(currentWeekPostsProvider(group));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              if (!_hasScheduledPop) {
                _hasScheduledPop = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.pop();
                });
              }
              return Container(color: Colors.black);
            }
            final targetIndex = widget.startFromLatest && !_userNavigated
                ? posts.length - 1
                : _currentIndex ?? 0;
            _currentIndex = targetIndex;
            final idx = targetIndex.clamp(0, posts.length - 1);
            final post = posts[idx];
            _precacheAdjacentImages(posts, idx);
            return _buildPostContent(context, group, post, posts);
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(
            child: Text("Error: $e", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    Post post,
    AsyncValue<Profile?> authorProfileAsync,
    AsyncValue<PostWithDetails> detailsAsync, {
    required bool shouldBlur,
    required int authorPostIndex,
    required int authorPostCount,
  }) {
    final cachedNickname = authorProfileAsync.valueOrNull?.nickname ?? '';
    final cachedAvatarUrl = authorProfileAsync.valueOrNull?.avatarUrl;

    if (shouldBlur) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cachedNickname.isNotEmpty)
            PostNudgeBanner(nickname: cachedNickname, onTap: _onPostTap),
          PostBottomBar(
            nickname:
                detailsAsync.valueOrNull?.authorNickname ?? cachedNickname,
            avatarUrl:
                detailsAsync.valueOrNull?.authorAvatarUrl ?? cachedAvatarUrl,
            date: formatTimeAgo(post.createdAt),
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
        _dismissedCommentIdByPost[post.id] == latestComment.id;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnComment =
        latestComment != null && latestComment.authorId == currentUserId;

    return Column(
      children: [
        if (latestComment != null && !isBannerDismissed && !isOwnComment)
          CommentNudgeBanner(
            comment: latestComment,
            onTap: () {
              setState(
                () => _dismissedCommentIdByPost[post.id] = latestComment.id,
              );
              _onCommentsTap(
                context,
                post,
                autofocus: false,
                scrollToCommentId: latestComment.id,
              );
            },
          ),

        PostBottomBar(
          nickname: d?.authorNickname ?? cachedNickname,
          avatarUrl: d?.authorAvatarUrl ?? cachedAvatarUrl,
          date: formatTimeAgo(post.createdAt),
          likeCount: _likeCountOverride ?? d?.likeCount ?? 0,
          commentCount: d?.commentCount ?? 0,
          isLiked: _likeOverride ?? d?.isLiked ?? false,
          likedUserIds: d?.likedUserIds ?? [],
          postIndex: authorPostIndex,
          postCount: authorPostCount,
          onLikeTap: () => _onLikeTap(
            post,
            _likeOverride ?? d?.isLiked ?? false,
            _likeCountOverride ?? d?.likeCount ?? 0,
          ),
          onCommentTap: () => _onCommentsTap(context, post, autofocus: true),
        ),
      ],
    );
  }

  Widget _buildPostContent(
    BuildContext context,
    Group group,
    Post post,
    List<Post> allPosts,
  ) {
    final authorProfileAsync = ref.watch(profileProvider(post.authorId));
    final detailsAsync = ref.watch(postWithDetailsProvider(post));
    final weekdayIndex = group.weekday - 1;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnPost = post.authorId == currentUserId;
    final beforeReveal = isCurrentWeekBeforeReveal(
      group,
      viewingWeekIndex: widget.weekIndex,
    );
    final shouldBlur = beforeReveal && !isOwnPost;
    final itemCount = allPosts.length;

    final authorPosts = allPosts
        .where((p) => p.authorId == post.authorId)
        .toList();
    final authorPostIndex = authorPosts.indexOf(post) + 1;
    final authorPostCount = authorPosts.length;

    final screenHeight = MediaQuery.of(context).size.height;
    final opacity = (1 - (_dragOffset / screenHeight) * 1.5).clamp(0.0, 1.0);
    final isDragging = _dragOffset > 0;
    final borderRadius = isDragging
        ? BorderRadius.vertical(top: Radius.circular(16))
        : BorderRadius.zero;

    return GestureDetector(
      onTapUp: (d) => _onTapUp(d, itemCount),
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: opacity),
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: shouldBlur
                        ? ImageFilter.blur(sigmaX: 30, sigmaY: 30)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: CachedPostImage(
                      imageUrl: post.photoUrl,
                      cacheKey: post.storagePath,
                      errorWidget: Container(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            "Failed to load",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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
                    currentIndex: _currentIndex!,
                    itemCount: itemCount,
                    onCloseTap: _onCloseTap,
                    onMoreTap: isOwnPost ? () => _onMoreTap(post) : null,
                    onPostTap:
                        widget.weekIndex == null ||
                            widget.weekIndex == groupWeekNumber(group)
                        ? _onPostTap
                        : null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: _buildBottomSection(
                      context,
                      post,
                      authorProfileAsync,
                      detailsAsync,
                      shouldBlur: shouldBlur,
                      authorPostIndex: authorPostIndex,
                      authorPostCount: authorPostCount,
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
