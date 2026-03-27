import 'package:bemyday/common/widgets/confirm_dialog.dart';
import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/features/comments/comments_sheet.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/features/post/widgets/post_content.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

bool _postIdEquals(String a, String b) =>
    a.toLowerCase() == b.toLowerCase();

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    super.key,
    this.group,
    this.weekIndex,
    this.startFromLatest = false,
    this.focusPostId,
  });

  static const routeName = "post";
  static const routeUrl = "/post";

  final Group? group;
  final int? weekIndex;
  final bool startFromLatest;

  /// 포스팅 직후 열릴 때 이 ID에 해당하는 슬라이드로 이동 (목록에 있을 때).
  final String? focusPostId;

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

  /// 이 화면 인스턴스에서 주 목록을 처음 받은 뒤 한 번만 상세를 강제 새로고침 (다시 들어올 때는 항상 최신).
  bool _didInitialPostDetailsInvalidate = false;

  /// 포스팅 직후 `focusPostId`가 목록에 안 보일 때 짧게 재요청 (디바이스/네트워크 타이밍)
  int _focusPostListRetryCount = 0;
  bool _focusPostListRetryScheduled = false;
  static const int _focusPostListRetryMax = 12;

  double _dragOffset = 0;
  late final AnimationController _dragAnimController;

  @override
  void initState() {
    super.initState();
    _dragAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _applyFreshOpenFromPosting();
  }

  /// 포스팅 직후 열린 화면은 이전 스와이프 상태를 쓰지 않음
  void _applyFreshOpenFromPosting() {
    if (widget.focusPostId != null) {
      _userNavigated = false;
      _currentIndex = null;
    }
  }

  @override
  void didUpdateWidget(covariant PostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final groupId = widget.group?.id;
    final oldGroupId = oldWidget.group?.id;
    if (widget.focusPostId != oldWidget.focusPostId ||
        groupId != oldGroupId ||
        widget.weekIndex != oldWidget.weekIndex) {
      _userNavigated = false;
      _currentIndex = null;
      _didInitialPostDetailsInvalidate = false;
      _focusPostListRetryCount = 0;
      _focusPostListRetryScheduled = false;
      _likeOverride = null;
      _likeCountOverride = null;
      _applyFreshOpenFromPosting();
    }
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

  void _onTapUp(TapUpDetails details, List<Post> allPosts) {
    final itemCount = allPosts.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final idx = _currentIndex ?? 0;
    if (tapX < screenWidth / 2) {
      if (idx > 0) {
        final newIdx = idx - 1;
        _userNavigated = true;
        setState(() {
          _currentIndex = newIdx;
          _likeOverride = null;
          _likeCountOverride = null;
        });
      }
    } else {
      if (idx < itemCount - 1) {
        final newIdx = idx + 1;
        _userNavigated = true;
        setState(() {
          _currentIndex = newIdx;
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
          groupId: post.groupId,
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
    await context.push(
      PostingAlbumScreen.routeUrl,
      extra: {
        'selectedWeekdayIndex': weekdayIndex,
        'replaceOnPostSuccess': true,
        if (widget.weekIndex != null) 'postScreenWeekIndex': widget.weekIndex,
      },
    );
    // 포스트 성공 시 PostingDecorateScreen에서 기존 PostScreen을 대체하여 방금 올린 포스트 표시
  }

  void _onMoreTap(Post post) async {
    final l10n = AppLocalizations.of(context)!;
    bool deleteRequested = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SheetSelect(
        items: [
          SheetItem(
            title: l10n.postDeleteTitle,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.postDeleteTitle,
      message: l10n.postDeleteConfirmMessage,
      confirmLabel: l10n.delete,
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
    final l10n = AppLocalizations.of(context)!;
    final group = widget.group;
    if (group == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.postNoGroup, style: TextStyle(color: Colors.white)),
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
            final focusId = widget.focusPostId;
            if (focusId != null &&
                !_userNavigated &&
                !posts.any((p) => _postIdEquals(p.id, focusId)) &&
                _focusPostListRetryCount < _focusPostListRetryMax &&
                !_focusPostListRetryScheduled) {
              _focusPostListRetryScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusPostListRetryScheduled = false;
                if (!mounted) return;
                setState(() => _focusPostListRetryCount++);
                if (widget.weekIndex != null) {
                  ref.invalidate(
                    weekPostsProvider(
                      (group: group, weekIndex: widget.weekIndex!),
                    ),
                  );
                } else {
                  ref.invalidate(currentWeekPostsProvider(group));
                }
              });
            }
            if (!_didInitialPostDetailsInvalidate) {
              _didInitialPostDetailsInvalidate = true;
              // PostContent의 watch보다 먼저 호출해 첫 페치와 invalidate가 겹치지 않게 함.
              for (final p in posts) {
                ref.invalidate(postWithDetailsProvider(p));
              }
            }
            final int idx;
            if (!_userNavigated) {
              final focus = widget.focusPostId;
              if (focus != null) {
                final i = posts.indexWhere((p) => _postIdEquals(p.id, focus));
                if (i >= 0) {
                  idx = i;
                } else {
                  idx = widget.startFromLatest
                      ? posts.length - 1
                      : (_currentIndex ?? 0);
                }
              } else if (widget.startFromLatest) {
                idx = posts.length - 1;
              } else {
                idx = _currentIndex ?? 0;
              }
            } else {
              idx = _currentIndex ?? 0;
            }
            final clampedIdx = idx.clamp(0, posts.length - 1);
            _currentIndex = clampedIdx;
            final post = posts[clampedIdx];
            _precacheAdjacentImages(posts, clampedIdx);
            return PostContent(
              key: ValueKey(post.id),
              group: group,
              post: post,
              allPosts: posts,
              currentIndex: clampedIdx,
              weekIndex: widget.weekIndex,
              dragOffset: _dragOffset,
              likeOverride: _likeOverride,
              likeCountOverride: _likeCountOverride,
              dismissedCommentIdByPost: _dismissedCommentIdByPost,
              onTapUp: _onTapUp,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onCloseTap: _onCloseTap,
              onMoreTap: _onMoreTap,
              onPostTap: _onPostTap,
              onLikeTap: _onLikeTap,
              onCommentTap:
                  (post, {bool autofocus = true, String? scrollToCommentId}) =>
                      _onCommentsTap(
                        context,
                        post,
                        autofocus: autofocus,
                        scrollToCommentId: scrollToCommentId,
                      ),
              onCommentNudgeDismiss: (postId, commentId) {
                setState(() => _dismissedCommentIdByPost[postId] = commentId);
              },
            );
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(
            child: Text(
              l10n.postError(e.toString()),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
