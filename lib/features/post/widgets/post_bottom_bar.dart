import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/widgets/likes_sheet.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostBottomBar extends StatefulWidget {
  final String nickname;
  final String? avatarUrl;
  final String? caption;
  final String date;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<String> likedUserIds;
  final int? postIndex;
  final int? postCount;
  final bool isOwnPost;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCaptionTap;
  final bool hideLikeComment;

  const PostBottomBar({
    super.key,
    required this.nickname,
    this.avatarUrl,
    this.caption,
    required this.date,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.likedUserIds = const [],
    this.postIndex,
    this.postCount,
    this.isOwnPost = false,
    this.onLikeTap,
    this.onCommentTap,
    this.onAvatarTap,
    this.onCaptionTap,
    this.hideLikeComment = false,
  });

  @override
  State<PostBottomBar> createState() => _PostBottomBarState();
}

class _PostBottomBarState extends State<PostBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _showCaptionShimmer =>
      widget.isOwnPost &&
      (widget.caption == null || widget.caption!.trim().isEmpty);

  void _onLikeLongPress(BuildContext context) {
    if (widget.likedUserIds.isEmpty) return;

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
            LikesSheet(likedUserIds: widget.likedUserIds),
      ),
    );
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final offset = _shimmerController.value * 3 - 1;
        return Opacity(
          opacity: 0.5,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.white38,
                  Colors.white,
                  Colors.white38,
                ],
                stops: [
                  (offset - 0.3).clamp(0.0, 1.0),
                  offset.clamp(0.0, 1.0),
                  (offset + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: child,
          ),
        );
      },
      child: Text(
        'Caption this..',
        style: TextStyle(
          fontSize: Sizes.size12,
          color: Colors.white,
          fontStyle: FontStyle.italic,
        ),
        overflow: TextOverflow.fade,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
      child: Row(
        children: [
          AvatarPackage(
            nickname: widget.nickname,
            avatarUrl: widget.avatarUrl,
            title: widget.nickname,
            isDarkOnly: true,
            subTitle: !_showCaptionShimmer
                ? (widget.caption != null && widget.caption!.trim().isNotEmpty
                    ? widget.caption!
                    : widget.postIndex != null && widget.postCount != null
                        ? l10n.postIndexOfCount(widget.postIndex!, widget.postCount!)
                        : null)
                : null,
            subTitleWidget: _showCaptionShimmer
                ? GestureDetector(
                    onTap: widget.onCaptionTap,
                    child: _buildShimmerText(),
                  )
                : null,
            childTitle: widget.date,
            onTap: widget.onAvatarTap,
          ),
          if (!widget.hideLikeComment) ...[
            Gaps.h16,
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onLikeTap,
                  onLongPress: () => _onLikeLongPress(context),
                  child: Row(
                    children: [
                      FaIcon(
                        widget.isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        size: Sizes.size24,
                        color: widget.isLiked ? Colors.redAccent : Colors.white,
                      ),
                      Gaps.h10,
                      if (widget.likeCount > 0) ...[
                        Text(
                          "${widget.likeCount}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                Gaps.h16,
                GestureDetector(
                  onTap: widget.onCommentTap,
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.comment,
                        size: Sizes.size24,
                        color: Colors.white,
                      ),
                      if (widget.commentCount > 0) ...[
                        Gaps.h10,
                        Text(
                          "${widget.commentCount}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
