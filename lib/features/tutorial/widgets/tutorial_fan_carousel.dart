import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/tutorial/data/tutorial_carousel_mock.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart'
    show InviteSheetBody, inviteCardDimensions;
import 'package:flutter/material.dart';

/// 튜토리얼 첫 페이지용. 월~일 7개 InviteCard 목업이 페이징 형태로 순환.
/// InviteScreen과 동일한 InviteSheetBody 사용.
class TutorialFanCarousel extends StatefulWidget {
  const TutorialFanCarousel({super.key});

  @override
  State<TutorialFanCarousel> createState() => _TutorialFanCarouselState();
}

class _TutorialFanCarouselState extends State<TutorialFanCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _focusDuration = Duration(seconds: 3);
  static const _transitionDuration = Duration(milliseconds: 600);
  static const _sideScale = 0.82;

  /// inviteCardDimensions는 60% 너비 → 페이지가 카드보다 넓어야 비율 유지
  static const _viewportFraction = 0.65;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(_focusDuration, () {
      if (!mounted) return;
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: _transitionDuration,
        curve: Curves.easeInOutCubic,
      );
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (_, cardH) = inviteCardDimensions(context);

    return SizedBox(
      height: cardH + Sizes.size24,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.none,
        itemCount: null,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final i = index % 7;
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value;
              if (_pageController.position.hasContentDimensions) {
                final page = _pageController.page ?? index.toDouble();
                value = page - index;
              } else {
                value = _currentIndex.toDouble() - index;
              }
              final scale = (1 - (value.abs() * (1 - _sideScale)))
                  .clamp(_sideScale, 1.0);

              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Center(
              child: InviteSheetBody(
                weekdayName: weekdays[i].name,
                inviterNickname: tutorialCarouselMocks[i].nickname,
                inviterAvatarUrl: tutorialCarouselMocks[i].avatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
