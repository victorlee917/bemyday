import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// 현재 week에 포스트가 없을 때 표시하는 빈 상태 위젯
///
/// - [weekdayIndex]: 요일 인덱스 (0=월 ~ 6=일)
/// - [onPostTap]: 포스트 추가 버튼 탭 시 호출 (null이면 PostingAlbumScreen으로 이동)
class PostEmpty extends StatelessWidget {
  const PostEmpty({super.key, required this.weekdayIndex, this.onPostTap});

  final int weekdayIndex;
  final VoidCallback? onPostTap;

  void _onPostTap(BuildContext context) async {
    if (onPostTap != null) {
      onPostTap!();
    } else {
      final result = await context.push(
        PostingAlbumScreen.routeUrl,
        extra: weekdayIndex,
      );
      if (result is Group && context.mounted) {
        context.push(
          PostScreen.routeUrl,
          extra: {'group': result, 'startFromLatest': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onPostTap(context),
      child: Stack(
        children: [
          FractionallySizedBox(
            heightFactor: 0.95,
            child: AspectRatio(
              aspectRatio: ARatio.common,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? CustomColors.clickableAreaDark
                      : CustomColors.clickableAreaLight,
                  border: BoxBorder.all(
                    color: isDarkMode(context)
                        ? CustomColors.borderDark
                        : CustomColors.borderLight,
                    width: Sizes.size1,
                  ),
                  borderRadius: BorderRadius.circular(RValues.thumbnail),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsetsGeometry.symmetric(
                      horizontal: Paddings.scaffoldH,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.circlePlus),
                        Gaps.v16,
                        Text(
                          "No post yet",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        Gaps.v8,
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            'Add post',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
