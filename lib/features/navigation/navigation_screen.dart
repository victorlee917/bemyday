import 'dart:io';

import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/home/providers/home_provider.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/features/friends/friends_screen.dart';
import 'package:bemyday/features/home/home_screen.dart';
import 'package:bemyday/features/my/my_screen.dart';
import 'package:bemyday/features/navigation/widgets/navigation_tab.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  static const String routeName = "navigation";
  static const String routeUrl = "/";

  final String tab;

  /// /home?weekday=N으로 진입 시 HomeScreen에 전달 (0~6)
  final int? initialWeekdayIndex;

  /// invitation_token이 있으면 바텀시트로 초대 화면 표시
  final String? invitationToken;

  const NavigationScreen({
    super.key,
    required this.tab,
    this.initialWeekdayIndex,
    this.invitationToken,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _tabs = ["friends", "home", "my"];

  late int _selectedIndex;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _animation = Tween(
    begin: 0.0,
    end: 0.125, // 45도 = X자
  ).animate(_animationController);

  @override
  void initState() {
    super.initState();
    _selectedIndex = _tabs.indexOf(widget.tab);
    if (_selectedIndex != 1) {
      _animationController.value = 0.125;
    }
    if (widget.invitationToken != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showInvitationSheetIfNeeded(),
      );
    }
  }

  @override
  void didUpdateWidget(NavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invitationToken != null &&
        widget.invitationToken != oldWidget.invitationToken) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showInvitationSheetIfNeeded(),
      );
    }
    // 딥링크 등으로 탭 변경 시 동기화
    if (widget.tab != oldWidget.tab) {
      _selectedIndex = _tabs.indexOf(widget.tab);
      if (_selectedIndex != 1 && _animationController.value != 0.125) {
        _animationController.value = 0.125;
      } else if (_selectedIndex == 1 && _animationController.value != 0) {
        _animationController.value = 0;
      }
    }
  }

  Future<void> _showInvitationSheetIfNeeded() async {
    final token = widget.invitationToken;
    if (token == null || !mounted) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    context.go('/${widget.tab}');
    if (!mounted) return;
    await showInvitationSheet(context, ref, inviteToken: token);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index != 1) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    setState(() => _selectedIndex = index);
  }

  void _onCenterButtonTap() async {
    if (_selectedIndex != 1) {
      _onNavTap(1);
      return;
    }

    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
    if (groups.isEmpty) {
      showInviteSheet(
        context,
        ref,
        selectedWeekdayIndex: ref.read(homeWeekdayIndexProvider),
      );
    } else {
      final selectedIndex = ref.read(homeWeekdayIndexProvider);
      final dbWeekday = selectedIndex + 1;
      final hasGroup = groups.any((g) => g.weekday == dbWeekday);

      final weekdayIndex = hasGroup ? selectedIndex : null;

      final result = await context.push(
        PostingAlbumScreen.routeUrl,
        extra: weekdayIndex,
      );
      if (result is Group && mounted) {
        context.push(
          PostScreen.routeUrl,
          extra: {'group': result, 'startFromLatest': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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
            child: HomeScreen(
              bottomPadding: totalBottomPadding,
              initialWeekdayIndex: widget.initialWeekdayIndex,
            ),
          ),
          Offstage(
            offstage: _selectedIndex != 2,
            child: MyScreen(bottomPadding: totalBottomPadding),
          ),
          // 하단 그라데이션
          if (_selectedIndex != 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: totalBottomPadding + 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: Platform.isAndroid ? Paddings.scaffoldV : 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _selectedIndex == 1 ? 240 : 60, // 고정 너비
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDarkMode(context)
                          ? CustomColors.clickableAreaDark
                          : CustomColors.clickableAreaLight,
                      border: Border.all(
                        color: isDarkMode(context)
                            ? CustomColors.borderDark
                            : CustomColors.borderLight,
                      ),
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
                            icon: FontAwesomeIcons.solidCalendarDays,
                            onTap: () => _onNavTap(0),
                          ),
                        ],
                        GestureDetector(
                          onTap: () => _onCenterButtonTap(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDarkMode(context)
                                      ? Colors.black
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: RotationTransition(
                                    turns: _animation,
                                    child: FaIcon(
                                      FontAwesomeIcons.plus,
                                      size: Sizes.size24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedIndex == 1) ...[
                          NavigationTab(
                            text: "My",
                            isSelected: _selectedIndex == 2,
                            icon: FontAwesomeIcons.solidUser,
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
