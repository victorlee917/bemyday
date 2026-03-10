import 'package:bemyday/common/widgets/async_value_builder.dart';
import 'package:bemyday/common/widgets/vacant_page.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/home/providers/home_provider.dart';
import 'package:bemyday/features/home/widgets/weekday_dial.dart';
import 'package:bemyday/features/home/widgets/weekday_occupied.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.bottomPadding,
    this.initialWeekdayIndex,
  });

  final double bottomPadding;

  /// 초대 링크 등으로 특정 그룹으로 진입 시 사용 (0~6)
  final int? initialWeekdayIndex;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PageController? _pageController;
  int _weekdayIndex = 0;

  /// 최초 포커스 요일: 남은 시간 가장 적은 그룹 → 없으면 당일 요일
  int _computeInitialFocusWeekdayIndex(List<Group> groups) {
    return computeSoonestWeekdayIndex(groups);
  }

  static const int _pageCount = 21;

  void _syncWeekdayFromPage() {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    final page = controller.page?.round() ?? controller.initialPage;
    final index = page % 7;
    if (ref.read(homeWeekdayIndexProvider) != index) {
      ref.read(homeWeekdayIndexProvider.notifier).state = index;
    }
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
    _pageController?.removeListener(_syncWeekdayFromPage);
    _pageController?.dispose();
    super.dispose();
  }

  void _onInviteTap(int weekdayIndex) {
    showInviteSheet(context, ref, selectedWeekdayIndex: weekdayIndex);
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(currentUserGroupsProvider);

    return Column(
      children: [
        AppBar(title: WeekdayDial(weekdayIndex: _weekdayIndex)),
        Expanded(
          child: AsyncValueBuilder<List<Group>>(
            value: groupsAsync,
            data: (groups) {
              final groupByWeekday = {
                for (final g in groups) g.weekday: g,
              };
              final targetIndex = widget.initialWeekdayIndex != null
                  ? widget.initialWeekdayIndex!.clamp(0, 6)
                  : _computeInitialFocusWeekdayIndex(groups);
              final targetPage = 7 + targetIndex;

              if (_pageController == null) {
                _pageController = PageController(
                  initialPage: targetPage,
                  viewportFraction: 0.9,
                );
                _pageController!.addListener(_syncWeekdayFromPage);
                _weekdayIndex = targetIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final notifier = ref.read(homeWeekdayIndexProvider.notifier);
                    if (notifier.state != targetIndex) {
                      notifier.state = targetIndex;
                    }
                  }
                });
              }

              return PageView.builder(
                controller: _pageController!,
                itemCount: _pageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final weekdayIndex = index % 7;
                  final dbWeekday = weekdayIndex + 1;
                  final group = groupByWeekday[dbWeekday];
                  final controller = _pageController!;

                  return RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        double value = 1.0;
                        double rotationValue = 0.0;
                        if (controller.position.haveDimensions) {
                          final page = controller.page! - index;
                          value = (1 - (page.abs() * 0.3)).clamp(0.0, 1.0);
                          rotationValue = page * 0.3;
                        }

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotationValue),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsetsGeometry.only(
                          bottom: widget.bottomPadding,
                        ),
                        child: group != null
                            ? WeekdayOccupied(
                                weekdayIndex: weekdayIndex,
                                group: group,
                              )
                            : VacantPage(
                                message:
                                    "Who's your ${weekdays[weekdayIndex].name}?",
                                onInviteTap: () =>
                                    _onInviteTap(weekdayIndex),
                              ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
