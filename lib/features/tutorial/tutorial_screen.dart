import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/start/start_screen.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/features/tutorial/widgets/tutorial_fan_carousel.dart';
import 'package:bemyday/features/tutorial/widgets/tutorial_post_reveal.dart';
import 'package:bemyday/features/tutorial/widgets/tutorial_post_stack.dart';
import 'package:bemyday/features/tutorial/widgets/tutorial_post_stack_with_blur.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  static const routeName = "tutorial";
  static const routeUrl = "/tutorial";

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentIndex = 0;

  static const _fadeDuration = Duration(milliseconds: 400);

  void _onNextTap() {
    if (_currentIndex < 3) {
      setState(() => _currentIndex++);
    } else {
      _showStartBottomSheet();
    }
  }

  void _showStartBottomSheet() {
    final router = GoRouter.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.4,
        decoration: BoxDecoration(
          color: isDarkMode(sheetContext)
              ? CustomColors.backgroundColorDark
              : CustomColors.backgroundColorLight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RValues.bottomsheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: StartScreen(router: router),
      ),
    );
  }

  /// 1. 최상단 로고 영역 (고정)
  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gaps.v36,
        Container(
          width: Sizes.size64,
          height: Sizes.size64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.size16),
            border: Border.all(
              color: isDarkMode(context)
                  ? CustomColors.borderDark
                  : CustomColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 10),
                blurRadius: 15,
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.size14),
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size1),
              child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
            ),
          ),
        ),
        Gaps.v28,
      ],
    );
  }

  /// 2. 가변 시각적 설명 영역 (비율)
  Widget _buildVisualSection(int index) {
    switch (index) {
      case 0:
        return TutorialFanCarousel(key: ValueKey(index));
      case 1:
        return Padding(
          key: ValueKey(index),
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: const TutorialPostStack(),
        );
      case 2:
        return SizedBox(
          height: 380,
          child: TutorialPostReveal(key: ValueKey(index)),
        );
      case 3:
        return TutorialPostStackWithBlur(key: ValueKey(index));
      default:
        return SizedBox.shrink(key: ValueKey(index));
    }
  }

  /// 3. 가변 타이틀 영역 (비율)
  Widget _buildTitleSection(int index) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.tutorialTitle0,
      l10n.tutorialTitle1,
      l10n.tutorialTitle2,
      l10n.tutorialTitle3,
    ];
    if (index < 0 || index >= titles.length) return const SizedBox.shrink();
    return Padding(
      key: ValueKey(index),
      padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
      child: Text(
        titles[index],
        style: GoogleFonts.darumadropOne(fontSize: Sizes.size28),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 4. 버튼 영역 (고정)
  Widget _buildButtonSection() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Paddings.scaffoldH,
          right: Paddings.scaffoldH,
          bottom: Paddings.scaffoldV,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gaps.v16,
            GestureDetector(
              onTap: _onNextTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Paddings.buttonH,
                  vertical: Paddings.buttonV,
                ),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(RValues.button),
                ),
                child: Text(
                  _currentIndex == 3
                      ? l10n.tutorialButtonStart
                      : l10n.tutorialButtonNext,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _titleGap = Gaps.v2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? CustomColors.backgroundColorDark
          : CustomColors.backgroundColorLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 최상단 로고 영역 (고정)
            _buildLogoSection(),
            // 2. 가변 시각적 설명 영역 (비율 3) - 콘텐츠 화면 중앙 배치
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Sizes.size24),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: _fadeDuration,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _buildVisualSection(_currentIndex),
                  ),
                ),
              ),
            ),
            // 타이틀과 시각 영역·버튼 영역 간 동일 간격
            _titleGap,
            // 3. 가변 타이틀 영역 (비율 1)
            Flexible(
              flex: 1,
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildTitleSection(_currentIndex),
              ),
            ),
            _titleGap,
          ],
        ),
      ),
      bottomNavigationBar: _buildButtonSection(),
    );
  }
}
