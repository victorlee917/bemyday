import 'package:bemyday/common/widgets/vacant_button.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/home/widgets/weekday_dial.dart';
import 'package:bemyday/features/home/widgets/weekday_occupied.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bottomPadding});

  final double bottomPadding;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  int _weekdayIndex = 0;

  @override
  void initState() {
    super.initState();
    // initialPage를 weekdayIndex와 맞춤 (5000은 4번째 요일, 5000-4 = 4996은 0번째 요일)
    _pageController = PageController(
      initialPage: 5000 - (5000 % 7) + _weekdayIndex,
      viewportFraction: 0.9,
    );
    _animationController = AnimationController(
      vsync: this,
      lowerBound: 1.0,
      upperBound: 3,
      value: 3,
      duration: Duration(milliseconds: 200),
    );
  }

  void _onPageChanged(int page) {
    final newWeekdayIndex = page % 7;
    if (_weekdayIndex != newWeekdayIndex) {
      setState(() {
        _weekdayIndex = newWeekdayIndex;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Future<void> _onRefresh() {
  //   return Future.delayed(const Duration(seconds: 3));
  // }

  // void _onCommentsTap(BuildContext context) async {
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => const CommentsSheet(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: WeekdayDial(weekdayIndex: _weekdayIndex)),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 10000,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }

                  // 회전 각도 계산 (원형 효과)
                  double rotationValue = 0.0;
                  if (_pageController.position.haveDimensions) {
                    rotationValue = (_pageController.page! - index) * 0.3;
                  }

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 원근감
                      ..rotateY(rotationValue), // Y축 회전 (좌우로 회전)
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    bottom: widget.bottomPadding,
                  ),
                  child: WeekdayOccupied(weekdayIndex: _weekdayIndex),
                ),
                // VacantButton(
                //   text: "Who's your ${weekdays[_weekdayIndex].name}?",
                //   label: "Invite Friend",
                // ),
              );
            },
          ),
        ),
      ],
    );
  }
}
