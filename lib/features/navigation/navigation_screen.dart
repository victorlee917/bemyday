import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/features/friends/friends_screen.dart';
import 'package:bemyday/features/home/home_screen.dart';
import 'package:bemyday/features/my/my_screen.dart';
import 'package:bemyday/features/navigation/widgets/navigation_tab.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 300),
  );

  late final Animation<double> _animtaion = Tween(
    begin: 0.0,
    end: 0.125, // 45도 = X자
  ).animate(_animationController);

  void _onNavTap(int index) {
    if (index != 1) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(
      context,
    ).padding.bottom; // SafeArea 하단 패딩
    final navBarHeight = 70.0; // 네비게이션 바 높이
    final totalBottomPadding = bottomPadding + navBarHeight + 20;
    return Scaffold(
      body: Stack(
        children: [
          Offstage(
            offstage: _selectedIndex != 0,
            child: FriendsScreen(bottomPadding: totalBottomPadding),
          ),
          Offstage(
            offstage: _selectedIndex != 1,
            child: HomeScreen(bottomPadding: totalBottomPadding),
          ),
          Offstage(
            offstage: _selectedIndex != 2,
            child: MyScreen(bottomPadding: totalBottomPadding),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _selectedIndex == 1 ? 300 : 70, // 고정 너비
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: _selectedIndex == 1
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      children: [
                        if (_selectedIndex == 1) ...[
                          NavigationTab(
                            text: "Friends",
                            isSelected: _selectedIndex == 0,
                            icon: FontAwesomeIcons.house,
                            onTap: () => _onNavTap(0),
                          ),
                          Gaps.h16,
                        ],
                        GestureDetector(
                          onTap: () => _onNavTap(1),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: RotationTransition(
                                    turns: _animtaion,
                                    child: FaIcon(FontAwesomeIcons.plus),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedIndex == 1) ...[
                          Gaps.h16,
                          NavigationTab(
                            text: "My",
                            isSelected: _selectedIndex == 2,
                            icon: FontAwesomeIcons.person,
                            onTap: () => _onNavTap(2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
