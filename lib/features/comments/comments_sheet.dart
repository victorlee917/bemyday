import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/comments/providers/comment_provider.dart';
import 'package:bemyday/features/comments/widgets/comment_input_avatar.dart';
import 'package:bemyday/features/comments/widgets/comment_tile.dart';
import 'package:bemyday/features/comments/widgets/mention_text_editing_controller.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({
    super.key,
    required this.postId,
    required this.groupId,
    this.scrollController,
    required this.autofocus,
    this.onCommentAdded,
    this.scrollToCommentId,
  });

  final String postId;
  final String groupId;
  final bool autofocus;
  final ScrollController? scrollController;
  final VoidCallback? onCommentAdded;

  /// 이 댓글이 최상단에 보이도록 스크롤
  final String? scrollToCommentId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final MentionTextEditingController _commentController =
      MentionTextEditingController();
  String _comment = "";
  late final ScrollController _scrollController;
  bool _hasScrolledToComment = false;

  /// `@` 위치 (해당 위치부터 커서까지가 멘션 후보)
  int? _mentionStartIndex;
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _commentController.addListener(_syncFromController);
  }

  void _syncFromController() {
    if (!mounted) return;
    final text = _commentController.text;
    final cursor = _clampCursor(text, _commentController.selection.baseOffset);
    _updateMentionState(text, cursor);
    setState(() => _comment = text);
  }

  int _clampCursor(String text, int cursor) {
    if (cursor < 0) return 0;
    if (cursor > text.length) return text.length;
    return cursor;
  }

  /// 커서 앞의 "단어"가 `@...` 형태면 멘션 모드.
  int? _findMentionStart(String text, int cursor) {
    if (cursor <= 0) return null;
    var start = cursor - 1;
    while (start >= 0 && text[start] != ' ' && text[start] != '\n') {
      start--;
    }
    final wordStart = start + 1;
    if (wordStart >= cursor) return null;
    if (text[wordStart] != '@') return null;
    final segment = text.substring(wordStart + 1, cursor);
    if (segment.contains(' ') || segment.contains('\n')) return null;
    return wordStart;
  }

  void _updateMentionState(String text, int cursor) {
    final start = _findMentionStart(text, cursor);
    if (start == null) {
      _mentionStartIndex = null;
      _mentionQuery = '';
      return;
    }
    _mentionStartIndex = start;
    _mentionQuery = text.substring(start + 1, cursor);
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
    _commentController.removeListener(_syncFromController);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  void _applyMention(String nickname) {
    final start = _mentionStartIndex;
    if (start == null) return;
    final text = _commentController.text;
    final end = _clampCursor(text, _commentController.selection.baseOffset);
    final before = text.substring(0, start);
    final after = text.substring(end);
    final inserted = '@$nickname ';
    final newText = '$before$inserted$after';
    final newOffset = start + inserted.length;
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  Future<void> _onSendComment() async {
    final content = _comment.trim();
    if (content.isEmpty) return;
    _commentController.clear();
    setState(() {
      _comment = '';
      _mentionStartIndex = null;
      _mentionQuery = '';
    });
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

  static const _mentionListMaxHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final membersAsync = ref.watch(groupMembersOrderedProvider(widget.groupId));

    ref.listen(commentsProvider(widget.postId), (prev, next) {
      next.whenData((comments) {
        _scrollToCommentIfNeeded(comments);
      });
    });

    final showMention = _mentionStartIndex != null;
    final borderColor = isDarkMode(context)
        ? CustomColors.borderDark
        : CustomColors.borderLight;

    final mentionPanel = membersAsync.when(
      data: (members) {
        final others = currentUserId == null
            ? members
            : members.where((m) => m.userId != currentUserId).toList();
        final q = _mentionQuery.toLowerCase();
        final filtered = q.isEmpty
            ? others
            : others
                .where((m) => m.nickname.toLowerCase().contains(q))
                .toList();
        if (!showMention || filtered.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(bottom: Sizes.size8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RValues.button),
            child: BackdropFilter(
              filter: Blurs.backdrop,
              child: Container(
                constraints: BoxConstraints(maxHeight: _mentionListMaxHeight),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? Blurs.overlayColorDark
                      : Blurs.overlayColorLight,
                  borderRadius: BorderRadius.circular(RValues.button),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: Sizes.size8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: Sizes.size4),
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    return InkWell(
                      onTap: () => _applyMention(m.nickname),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Paddings.buttonH,
                          vertical: Sizes.size6,
                        ),
                        child: Row(
                          children: [
                            AvatarDefault(
                              nickname: m.nickname,
                              avatarUrl: m.avatarUrl,
                              radius: Sizes.size16,
                              borderColor: borderColor,
                            ),
                            SizedBox(width: Sizes.size10),
                            Expanded(
                              child: Text(
                                m.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: Sizes.size14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading: () {
        if (!showMention) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: Sizes.size8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RValues.button),
            child: BackdropFilter(
              filter: Blurs.backdrop,
              child: Container(
                padding: EdgeInsets.all(Paddings.buttonH),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? Blurs.overlayColorDark
                      : Blurs.overlayColorLight,
                  borderRadius: BorderRadius.circular(RValues.button),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: SizedBox(
                    width: Sizes.size20,
                    height: Sizes.size20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
    );

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
                    title: Text(l10n.commentsTitle),
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
                              child: Text(l10n.commentsError(e.toString())),
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

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      mentionPanel,
                      Row(
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
                                    onSubmitted: (_) => _onSendComment(),
                                    textInputAction: TextInputAction.send,
                                    keyboardType: TextInputType.text,
                                    maxLines: 1,
                                    style: TextStyle(fontSize: Sizes.size14),
                                    cursorHeight: Sizes.size14,
                                    cursorColor: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
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
                                      hintText: l10n.commentsHint,
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
