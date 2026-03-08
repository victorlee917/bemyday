import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/comments/providers/comment_provider.dart';
import 'package:bemyday/features/comments/widgets/comment_input_avatar.dart';
import 'package:bemyday/features/comments/widgets/comment_tile.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({
    super.key,
    required this.postId,
    this.scrollController,
    required this.autofocus,
    this.onCommentAdded,
    this.scrollToCommentId,
  });

  final String postId;
  final bool autofocus;
  final ScrollController? scrollController;
  final VoidCallback? onCommentAdded;

  /// 이 댓글이 최상단에 보이도록 스크롤
  final String? scrollToCommentId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  String _comment = "";
  late final ScrollController _scrollController;
  bool _hasScrolledToComment = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  void _scrollToCommentIfNeeded(List<dynamic> comments) {
    final targetId = widget.scrollToCommentId;
    if (targetId == null || _hasScrolledToComment) return;

    final index = comments.indexWhere((c) => c.id == targetId);
    if (index < 0) return;

    _hasScrolledToComment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      const estimatedItemHeight = 70.0;
      final offset = (index * estimatedItemHeight).toDouble();
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        offset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged(String value) {
    setState(() => _comment = value);
  }

  Future<void> _onSendComment() async {
    final content = _comment.trim();
    if (content.isEmpty) return;
    _commentController.clear();
    setState(() => _comment = '');
    await ref
        .read(commentRepositoryProvider)
        .createComment(widget.postId, content);
    ref.invalidate(commentsProvider(widget.postId));
    widget.onCommentAdded?.call();

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    final comments = await ref.read(commentsProvider(widget.postId).future);
    if (!mounted || comments.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _onClosePressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(commentsProvider(widget.postId), (prev, next) {
      next.whenData((comments) {
        _scrollToCommentIfNeeded(comments);
      });
    });
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: Scaffold(
        backgroundColor: isDarkMode(context)
            ? CustomColors.sheetColorDark
            : CustomColors.sheetColorLight,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: isDarkMode(context)
                        ? CustomColors.sheetColorDark
                        : CustomColors.sheetColorLight,
                    shape: Border(
                      bottom: BorderSide(
                        color: isDarkMode(context)
                            ? CustomColors.borderDark
                            : CustomColors.borderLight,
                        width: Widths.devider,
                      ),
                    ),
                    title: Text("Comments"),
                    actions: [
                      GestureDetector(
                        onTap: _onClosePressed,
                        child: FaIcon(
                          FontAwesomeIcons.circleXmark,
                          size: Sizes.size20,
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom:
                          kToolbarHeight +
                          MediaQuery.of(context).padding.bottom +
                          Paddings.scaffoldV,
                    ),
                    sliver: ref
                        .watch(commentsProvider(widget.postId))
                        .when(
                          data: (comments) => SliverList.separated(
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return CommentTile(
                                key: ValueKey(comment.id),
                                commentId: comment.id,
                                postId: widget.postId,
                                authorId: comment.authorId,
                                content: comment.content,
                                createdAt: comment.createdAt,
                                onCommentDeleted: widget.onCommentAdded,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 0),
                            itemCount: comments.length,
                          ),
                          loading: () => SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(Paddings.scaffoldV),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          error: (e, _) => SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(Paddings.scaffoldV),
                              child: Text("Error: $e"),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Paddings.scaffoldH,
                    vertical: Paddings.scaffoldV,
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(RValues.button),
                          child: BackdropFilter(
                            filter: Blurs.backdrop,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode(context)
                                    ? Blurs.overlayColorDark
                                    : Blurs.overlayColorLight,
                                borderRadius: BorderRadius.circular(
                                  RValues.button,
                                ),
                                border: Border.all(
                                  color: isDarkMode(context)
                                      ? CustomColors.borderDark
                                      : CustomColors.borderLight,
                                ),
                              ),
                              child: TextField(
                                controller: _commentController,
                                onChanged: _onCommentChanged,
                                style: TextStyle(fontSize: Sizes.size14),
                                cursorHeight: Sizes.size14,
                                decoration: InputDecoration(
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(
                                      left: Sizes.size10,
                                      right: Sizes.size8,
                                    ),
                                    child: CommentInputAvatar(),
                                  ),
                                  prefixIconConstraints: BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                  suffixIcon: _comment.trim().isNotEmpty
                                      ? GestureDetector(
                                          onTap: _onSendComment,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: Paddings.buttonH,
                                              left: Sizes.size8,
                                            ),
                                            child: FaIcon(
                                              FontAwesomeIcons.circleArrowUp,
                                              size: Sizes.size20,
                                            ),
                                          ),
                                        )
                                      : null,
                                  suffixIconConstraints: BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                  hintText: "Leave a comment...",
                                  hintStyle: TextStyle(
                                    color: isDarkMode(context)
                                        ? CustomColors.hintColorDark
                                        : CustomColors.hintColorLight,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Paddings.buttonH,
                                    vertical: Paddings.buttonV,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                      RValues.button,
                                    ),
                                  ),
                                ),
                                autocorrect: false,
                                autofocus: widget.autofocus,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
