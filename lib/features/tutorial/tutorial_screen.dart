import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/start/start_screen.dart';
import 'package:bemyday/features/tutorial/widgets/tutorial_page.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  static const routeName = "tutorial";
  static const routeUrl = "/tutorial";

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabController.animation?.addListener(_onAnimationChanged);
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_onAnimationChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onAnimationChanged() {
    final newIndex = _tabController.animation!.value.round();
    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _onNextTap() {
    if (_tabController.index < 2) {
      _tabController.animateTo(_tabController.index + 1);
    } else {
      context.go(StartScreen.routeUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? CustomColors.backgroundColorDark
          : CustomColors.backgroundColorLight,
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: TutorialPage(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: TutorialPage(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: TutorialPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                    _currentIndex == 2 ? "Start" : "Next",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
