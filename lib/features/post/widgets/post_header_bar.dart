import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/widgets/index_indicator.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// [PostScreen] 상단의 인덱스 인디케이터 + 요일/주차 정보 + 액션 버튼 영역.
class PostHeaderBar extends StatelessWidget {
  const PostHeaderBar({
    super.key,
    required this.weekdayName,
    required this.weekNumber,
    required this.currentIndex,
    required this.itemCount,
    required this.onCloseTap,
    this.onMoreTap,
    this.onPostTap,
  });

  final String weekdayName;
  final int weekNumber;
  final int currentIndex;
  final int itemCount;
  final VoidCallback onCloseTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onPostTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
        child: Column(
          children: [
            IndexIndicator(
              currentIndex: currentIndex,
              itemCount: itemCount,
            ),
            Gaps.v8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekdayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Opacity(
                      opacity: 0.5,
                      child: Text(
                        "Week$weekNumber",
                        style: TextStyle(
                          fontSize: Sizes.size12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: Sizes.size24,
                  children: [
                    if (onMoreTap != null)
                      GestureDetector(
                        onTap: onMoreTap,
                        child: FaIcon(
                          FontAwesomeIcons.ellipsis,
                          size: Sizes.size20,
                          color: Colors.white,
                        ),
                      ),
                    if (onPostTap != null)
                      GestureDetector(
                        onTap: onPostTap,
                        child: FaIcon(
                          FontAwesomeIcons.circlePlus,
                          size: Sizes.size20,
                          color: Colors.white,
                        ),
                      ),
                    GestureDetector(
                      onTap: onCloseTap,
                      child: FaIcon(
                        FontAwesomeIcons.circleXmark,
                        size: Sizes.size20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
