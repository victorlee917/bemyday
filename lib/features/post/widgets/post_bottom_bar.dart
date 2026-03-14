import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/widgets/likes_sheet.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostBottomBar extends StatelessWidget {
  final String nickname;
  final String? avatarUrl;
  final String date;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<String> likedUserIds;
  final int? postIndex;
  final int? postCount;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final bool hideLikeComment;

  const PostBottomBar({
    super.key,
    required this.nickname,
    this.avatarUrl,
    required this.date,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.likedUserIds = const [],
    this.postIndex,
    this.postCount,
    this.onLikeTap,
    this.onCommentTap,
    this.hideLikeComment = false,
  });

  void _onLikeLongPress(BuildContext context) {
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
      child: Row(
        children: [
          AvatarPackage(
            nickname: nickname,
            avatarUrl: avatarUrl,
            title: nickname,
            isDarkOnly: true,
            subTitle: postIndex != null && postCount != null
                ? l10n.postIndexOfCount(postIndex!, postCount!)
                : null,
            childTitle: date,
          ),
          if (!hideLikeComment)
            Row(
              children: [
                GestureDetector(
                  onTap: onLikeTap,
                  onLongPress: () => _onLikeLongPress(context),
                  child: Row(
                    children: [
                      FaIcon(
                        isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        size: Sizes.size24,
                        color: isLiked ? Colors.redAccent : Colors.white,
                      ),
                      Gaps.h10,
                      if (likeCount > 0) ...[
                        Text(
                          "$likeCount",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                Gaps.h16,
                GestureDetector(
                  onTap: onCommentTap,
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.comment,
                        size: Sizes.size24,
                        color: Colors.white,
                      ),
                      if (commentCount > 0) ...[
                        Gaps.h10,
                        Text(
                          "$commentCount",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
