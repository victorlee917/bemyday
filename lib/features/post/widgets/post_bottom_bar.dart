import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/widgets/likes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostBottomBar extends StatelessWidget {
  final String nickname;
  final String date;
  final int likeCount;
  final int commentCount;
  final List<String> likedUsers;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;

  const PostBottomBar({
    super.key,
    required this.nickname,
    required this.date,
    required this.likeCount,
    required this.commentCount,
    this.likedUsers = const [],
    this.onLikeTap,
    this.onCommentTap,
  });

  void _onLikeLongPress(BuildContext context) {
    if (likedUsers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => LikesSheet(
          likedUsers: likedUsers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
      child: Row(
        children: [
          AvatarPackage(
            nickname: nickname,
            title: "Bogus",
            isDarkOnly: true,
            subTitle: "Post 3 of 5",
            childTitle: "yesterday",
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onLikeTap,
                onLongPress: () => _onLikeLongPress(context),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.heart,
                      size: Sizes.size24,
                      color: Colors.white,
                    ),
                    Gaps.h10,
                    Text("3", style: TextStyle(color: Colors.white)),
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
                    Gaps.h10,
                    Text("3", style: TextStyle(color: Colors.white)),
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
