import 'dart:async';
import 'dart:ui';

import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart'
    show inviteCardDimensions;
import 'package:bemyday/features/tutorial/data/tutorial_day_mock.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

/// 튜토리얼용 PostStack. weekday_occupied.dart의 PostStack과 동일한 레이아웃·tilt 효과.
/// [dayIndex]가 있으면 해당 요일의 목업 이미지를 사용하고, 없으면 posts 이미지를 3초마다 순환.
class TutorialPostStack extends StatefulWidget {
  const TutorialPostStack({super.key, this.dayIndex});

  /// 요일 인덱스 (0=Monday ~ 6=Sunday). null이면 기본 posts 이미지 순환.
  final int? dayIndex;

  @override
  State<TutorialPostStack> createState() => _TutorialPostStackState();
}

class _TutorialPostStackState extends State<TutorialPostStack> {
  static const int _maxVisible = 4;
  static const _rotateInterval = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 400);

  static const _defaultAssetPaths = [
    'assets/mockups/posts/post1.jpg',
    'assets/mockups/posts/post2.jpg',
    'assets/mockups/posts/post3.jpg',
    'assets/mockups/posts/post4.jpg',
  ];

  int _rotationIndex = 0;
  Timer? _timer;

  List<String> get _imagePaths => widget.dayIndex != null
      ? tutorialDayMocks[widget.dayIndex! % tutorialDayMocks.length].imagePaths
      : _defaultAssetPaths;

  String _photoUrlAt(int slotIndex) =>
      _imagePaths[(slotIndex + _rotationIndex) % _imagePaths.length];

  @override
  void initState() {
    super.initState();
    if (widget.dayIndex == null) {
      _timer = Timer.periodic(_rotateInterval, (_) {
        if (mounted) {
          setState(
            () => _rotationIndex =
                (_rotationIndex + 1) % _defaultAssetPaths.length,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TutorialPostStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dayIndex != oldWidget.dayIndex && widget.dayIndex != null) {
      _rotationIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 첫 번째 인덱스 초대장 기준. 이전(0.896)의 1.2배
  static const _scaleFactor = 0.92; // 0.896 * 1.2

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final borderColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final bgColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final cardCount = _maxVisible;

    final (_, inviteCardH) = inviteCardDimensions(context);
    final cardHeight = inviteCardH * _scaleFactor;

    return SizedBox(
      height: cardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight;
          final cardWidth = cardHeight * ARatio.common;
          const spacing = 16.0;
          const angles = [-0.04, 0.0, 0.04, 0.08];
          final totalWidth = cardWidth + (cardCount - 1) * spacing;
          final startX = (constraints.maxWidth - totalWidth) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = cardCount - 1; i >= 0; i--)
                Positioned(
                  left: startX + i * spacing,
                  top: (constraints.maxHeight - cardHeight) / 2,
                  width: cardWidth,
                  height: cardHeight,
                  child: Transform.rotate(
                    angle: angles[i],
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
                      ),
                      child: Tilt(
                        tiltConfig: TiltConfig(
                          enableGestureTouch: false,
                          enableGestureHover: false,
                          enableGestureSensors: true,
                          angle: 4,
                          sensorFactor: 8,
                        ),
                        lightConfig: LightConfig(disable: true),
                        shadowConfig: ShadowConfig(disable: true),
                        borderRadius: BorderRadius.circular(RValues.thumbnail),
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: borderColor,
                                width: 5.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                RValues.thumbnail,
                              ),
                              color: bgColor,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                RValues.thumbnail - 5.0,
                              ),
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 0,
                                  sigmaY: 0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: _fadeDuration,
                                  switchInCurve: Curves.easeIn,
                                  switchOutCurve: Curves.easeOut,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: SizedBox.expand(
                                    key: ValueKey(_photoUrlAt(i)),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.hardEdge,
                                      child: CachedPostImage(
                                        imageUrl: _photoUrlAt(i),
                                        cacheKey: 'tutorial-$i',
                                        placeholderColor: bgColor,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
}
