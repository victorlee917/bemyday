import 'dart:async';

import 'package:bemyday/common/widgets/avatar/horizontal_avatar_stack.dart';
import 'package:bemyday/common/widgets/blur_overlay_card.dart';
import 'package:bemyday/common/widgets/stat/stats_collection.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart'
    show inviteCardDimensions;
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bemyday/features/tutorial/data/tutorial_day_mock.dart';

import 'tutorial_post_stack.dart';

/// 튜토리얼 마지막 페이지용. TutorialPostStack(4장) 위에 blur 처리된 container 오버레이.
/// - Container 높이: PostStack의 1/2
/// - Container 너비: PostStack 총 너비의 1.5배
class TutorialPostStackWithBlur extends StatefulWidget {
  const TutorialPostStackWithBlur({super.key});

  @override
  State<TutorialPostStackWithBlur> createState() =>
      _TutorialPostStackWithBlurState();
}

class _TutorialPostStackWithBlurState extends State<TutorialPostStackWithBlur> {
  static const _scaleFactor = 0.9;
  static const _postStackSpacing = 16.0;
  static const _postStackCardCount = 4;

  /// PostStack(스케일 적용 후) 너비의 1.5배
  static const _blurWidthFactor = 1.5;

  int _dayIndex = 0;
  Timer? _dayCycleTimer;

  @override
  void initState() {
    super.initState();
    _dayCycleTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _dayIndex = (_dayIndex + 1) % tutorialDayMocks.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _dayCycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (_, postStackCardHeight) = inviteCardDimensions(context);
    final stackHeight = postStackCardHeight * _scaleFactor;
    final blurContainerHeight = stackHeight / 1.35;
    final dark = isDarkMode(context);
    final l10n = AppLocalizations.of(context)!;

    final cardWidth = postStackCardHeight * ARatio.common;
    final postStackTotalWidth =
        cardWidth + (_postStackCardCount - 1) * _postStackSpacing;
    final postStackScaledWidth = postStackTotalWidth * _scaleFactor;
    final availableWidth =
        MediaQuery.of(context).size.width - Paddings.scaffoldH * 2;
    final blurContainerWidth = (postStackScaledWidth * _blurWidthFactor).clamp(
      0.0,
      availableWidth * 0.85,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
      child: SizedBox(
        height: stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: _scaleFactor,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: postStackCardHeight,
                child: TutorialPostStack(dayIndex: _dayIndex),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: blurContainerHeight,
              child: Center(
                child: BlurOverlayCard(
                  width: blurContainerWidth,
                  height: blurContainerHeight,
                  dark: dark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tutorialDayMocks[_dayIndex].weekday,
                        style: GoogleFonts.darumadropOne(
                          fontSize: Sizes.size20,
                        ),
                      ),
                      Gaps.v20,
                      HorizontalAvatarStack(
                        dark: dark,
                        members: _tutorialMembers(
                          tutorialDayMocks[_dayIndex].avatarNicknames,
                          tutorialDayMocks[_dayIndex].avatarUrls,
                        ),
                      ),
                      Gaps.v8,
                      Text(
                        tutorialDayMocks[_dayIndex].groupName,
                        style: TextStyle(
                          fontSize: Sizes.size14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gaps.v16,
                      StatsCollection(
                        stats: tutorialDayMocks[_dayIndex].statItems(
                          l10n.statWeeks,
                          l10n.statStreaks,
                          l10n.statPosts,
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

List<({String? avatarUrl, String nickname})> _tutorialMembers(
  List<String> nicknames,
  List<String> avatarUrls,
) {
  return List.generate(nicknames.length, (i) {
    final nickname = nicknames[i];
    final avatarUrl = i < avatarUrls.length ? avatarUrls[i] : null;
    return (avatarUrl: avatarUrl, nickname: nickname);
  });
}
