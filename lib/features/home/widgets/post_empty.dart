import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// 현재 week에 포스트가 없을 때 표시하는 빈 상태 위젯
///
/// - [weekdayIndex]: 요일 인덱스 (0=월 ~ 6=일)
/// - [onPostTap]: 포스트 추가 버튼 탭 시 호출 (null이면 PostingAlbumScreen으로 이동)
/// - [compactForBlur]: true면 PostStack 1장 레이아웃처럼 표시하고, blur에 가려지지 않는
///   윗 부분에 + 아이콘만 노출 (GroupPostStackWithBlur용)
class PostEmpty extends StatelessWidget {
  const PostEmpty({
    super.key,
    required this.weekdayIndex,
    this.onPostTap,
    this.compactForBlur = false,
  });

  final int weekdayIndex;
  final VoidCallback? onPostTap;
  final bool compactForBlur;

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
      child: compactForBlur
          ? _buildCompactForBlur(context)
          : _buildDefault(context),
    );
  }

  /// PostStack 1장 레이아웃과 동일. + 아이콘은 blur에 가려지지 않는 윗 부분에 배치.
  Widget _buildCompactForBlur(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const angle = -0.04;
    final dark = isDarkMode(context);
    final borderColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final bgColor = borderColor;

    return FractionallySizedBox(
      heightFactor: 0.95,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight;
          final cardWidth = cardHeight * ARatio.common;
          final startX = (constraints.maxWidth - cardWidth) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: startX,
                top: (constraints.maxHeight - cardHeight) / 2,
                width: cardWidth,
                height: cardHeight,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RValues.thumbnail),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: borderColor, width: 5.0),
                      color: bgColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        RValues.thumbnail - 5,
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.6),
                        child: Column(
                          children: [
                            Gaps.v32,
                            FaIcon(
                              FontAwesomeIcons.circlePlus,
                              color: dark ? Colors.white : Colors.black,
                            ),
                            Gaps.v12,
                            Text(
                              l10n.addPosts,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefault(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
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
                border: Border.all(
                  color: isDarkMode(context)
                      ? CustomColors.borderDark
                      : CustomColors.borderLight,
                  width: Sizes.size1,
                ),
                borderRadius: BorderRadius.circular(RValues.thumbnail),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.circlePlus),
                      Gaps.v16,
                      Text(
                        l10n.noPostYet,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Gaps.v8,
                      Opacity(
                        opacity: 0.5,
                        child: Text(
                          l10n.addPosts,
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
    );
  }
}
