import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostCommentBubble extends StatelessWidget {
  final String content;
  final VoidCallback? onTap;

  const PostCommentBubble({super.key, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: Paddings.scaffoldH),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 240,
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.size16,
                vertical: Sizes.size6,
              ),
              decoration: BoxDecoration(
                color: CustomColors.clickableAreaLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Sizes.size24),
                  topRight: Radius.circular(Sizes.size24),
                  bottomLeft: Radius.circular(Sizes.size24),
                ),
              ),
              child: Text(
                content,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.black),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            Gaps.h12,
            FaIcon(
              FontAwesomeIcons.peopleArrows,
              size: Sizes.size20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
