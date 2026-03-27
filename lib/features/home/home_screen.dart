import 'package:bemyday/common/widgets/async_value_builder.dart';
import 'package:bemyday/common/widgets/vacant_page.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/home/providers/home_provider.dart';
import 'package:bemyday/features/home/widgets/weekday_dial.dart';
import 'package:bemyday/features/home/widgets/weekday_occupied.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  bool _userHasNavigated = false;

  /// 요일(0~6)로 다시 들어올 때마다 증가 → 이름 없는 그룹 헤더 닉네임 재추첨
  final Map<int, int> _headlineShuffleEpoch = {};

  /// 최초 포커스 요일: 남은 시간 가장 적은 그룹 → 없으면 당일 요일
  int _computeInitialFocusWeekdayIndex(List<Group> groups) {
    return computeSoonestWeekdayIndex(groups);
  }

  static const int _pageMultiplier = 1000;

  /// 고정 인디케이터 아래 여백 + 인디케이터 높이만큼 페이지 하단 패딩
  static const double _indicatorReserve = 40;

  /// 인디케이터·드래그 영역 최대 가로 (화면 전체 쓰지 않을 때). 더 넓히려면 값만 키움.
  static const double _weekdayIndicatorMaxWidth = 120;

  void _goToWeekdayIndex(
    int targetWeekday, {
    _IndicatorSeekMode mode = _IndicatorSeekMode.tap,
  }) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    final page = c.page;
    if (page == null) return;
    final rounded = page.round();
    const n = 7;
    final cur = ((rounded % n) + n) % n;
    var diff = targetWeekday - cur;
    if (diff > 3) diff -= n;
    if (diff < -3) diff += n;
    final dest = rounded + diff;
    if (dest == rounded) return;
    switch (mode) {
      case _IndicatorSeekMode.tap:
        c.animateToPage(
          dest,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      case _IndicatorSeekMode.scrub:
        // 인덱스가 바뀔 때만(이미 위에서 dest != rounded) 짧은 선택 피드백
        HapticFeedback.selectionClick();
        c.animateToPage(
          dest,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        );
    }
  }

  void _syncWeekdayFromPage() {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    final page = controller.page?.round() ?? controller.initialPage;
    final index = page % 7;
    if (ref.read(homeWeekdayIndexProvider) != index) {
      ref.read(homeWeekdayIndexProvider.notifier).state = index;
    }
    if (_weekdayIndex != index) {
      setState(() => _weekdayIndex = index);
    }
  }

  void _onPageChanged(int page) {
    _userHasNavigated = true;
    final newWeekdayIndex = page % 7;
    // _syncWeekdayFromPage가 스크롤 중에 이미 _weekdayIndex를 맞추므로,
    // 여기서는 비교 없이 "도착한 페이지" 요일만 항상 bump 해야 재진입 시 닉네임이 바뀐다.
    setState(() {
      _headlineShuffleEpoch[newWeekdayIndex] =
          (_headlineShuffleEpoch[newWeekdayIndex] ?? 0) + 1;
      _weekdayIndex = newWeekdayIndex;
    });
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
              final groupByWeekday = {for (final g in groups) g.weekday: g};
              final targetIndex = widget.initialWeekdayIndex != null
                  ? widget.initialWeekdayIndex!.clamp(0, 6)
                  : _computeInitialFocusWeekdayIndex(groups);
              final targetPage = _pageMultiplier * 7 + targetIndex;

              if (_pageController == null) {
                _pageController = PageController(
                  initialPage: targetPage,
                  viewportFraction: 0.9,
                );
                _pageController!.addListener(_syncWeekdayFromPage);
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _pageController == null) return;
                final controller = _pageController!;
                if (controller.hasClients) {
                  final currentPage =
                      controller.page?.round() ?? controller.initialPage;
                  final weekdayFromPage = currentPage % 7;
                  if (!_userHasNavigated && currentPage != targetPage) {
                    controller.jumpToPage(targetPage);
                    setState(() => _weekdayIndex = targetIndex);
                  } else if (_weekdayIndex != weekdayFromPage) {
                    setState(() => _weekdayIndex = weekdayFromPage);
                  }
                }
                final notifier = ref.read(homeWeekdayIndexProvider.notifier);
                final syncIndex = controller.hasClients
                    ? ((controller.page?.round() ?? controller.initialPage) % 7)
                    : targetIndex;
                if (notifier.state != syncIndex) {
                  notifier.state = syncIndex;
                }
              });

              final pageController = _pageController!;
              final bottomInset = widget.bottomPadding + _indicatorReserve;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: pageController,
                    itemCount: null,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final weekdayIndex = index % 7;
                      final dbWeekday = weekdayIndex + 1;
                      final group = groupByWeekday[dbWeekday];

                      return RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            double rotationValue = 0.0;
                            if (pageController.position.haveDimensions) {
                              final page = pageController.page! - index;
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
                              bottom: bottomInset,
                            ),
                            child: group != null
                                ? WeekdayOccupied(
                                    weekdayIndex: weekdayIndex,
                                    group: group,
                                    shuffleEpoch:
                                        _headlineShuffleEpoch[weekdayIndex] ??
                                        0,
                                  )
                                : Center(
                                    child: VacantPage(
                                      message:
                                          "Who's your ${weekdays[weekdayIndex].name}?",
                                      onInviteTap: () =>
                                          _onInviteTap(weekdayIndex),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  // 바닥 오프셋: `bottom` / 좌우 여백: `left`·`right` / 가로 한도: `_weekdayIndicatorMaxWidth`
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: widget.bottomPadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _weekdayIndicatorMaxWidth,
                        ),
                        child: _WeekdayIndicatorDragHost(
                          onSeekWeekday: _goToWeekdayIndex,
                          isDark: isDarkMode(context),
                          indicator: SmoothPageIndicator(
                            controller: pageController,
                            count: 7,
                            effect: ScrollingDotsEffect(
                              dotHeight: 6,
                              dotWidth: 6,
                              spacing: 8,
                              radius: 3,
                              maxVisibleDots: 7,
                              activeDotScale: 1.35,
                              smallDotScale: 0.65,
                              activeDotColor: isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black87,
                              dotColor: isDarkMode(context)
                                  ? Colors.white24
                                  : Colors.black26,
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
        ),
      ],
    );
  }
}

enum _IndicatorSeekMode { tap, scrub }

/// 하단 인디케이터: 드래그·탭으로 요일(0~6) 이동.
///
/// - **화면에서의 위치**: [HomeScreen]의 `Positioned` + 가로는 `ConstrainedBox(maxWidth: _weekdayIndicatorMaxWidth)`.
/// - **배경 pill·터치 높이**: [_kChromePadding] · [_kHitHeight].
class _WeekdayIndicatorDragHost extends StatefulWidget {
  const _WeekdayIndicatorDragHost({
    required this.onSeekWeekday,
    required this.indicator,
    required this.isDark,
  });

  final void Function(int weekday, {_IndicatorSeekMode mode}) onSeekWeekday;
  final Widget indicator;
  final bool isDark;

  @override
  State<_WeekdayIndicatorDragHost> createState() =>
      _WeekdayIndicatorDragHostState();
}

class _WeekdayIndicatorDragHostState extends State<_WeekdayIndicatorDragHost> {
  static const int _n = 7;

  /// 롱프레스/드래그 시 pill 안쪽 여백 (크기 줄이려면 여기)
  static const EdgeInsets _kChromePadding = EdgeInsets.symmetric(
    horizontal: Sizes.size2,
    vertical: Sizes.size2,
  );

  /// 터치·정렬용 높이 (줄이면 히트 영역도 같이 줄어듦)
  static const double _kHitHeight = 16;

  int? _lastScrubIndex;
  bool _dragging = false;
  bool _longPressing = false;

  bool get _chrome => _dragging || _longPressing;

  void _indexAt(Offset globalPosition, {required _IndicatorSeekMode mode}) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final w = box.size.width;
    if (w <= 0) return;
    final idx = (local.dx / w * _n).floor().clamp(0, _n - 1);
    if (mode == _IndicatorSeekMode.scrub) {
      if (_lastScrubIndex == idx) return;
      _lastScrubIndex = idx;
    }
    widget.onSeekWeekday(idx, mode: mode);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? CustomColors.borderDark
        : CustomColors.borderLight;
    final fillColor = widget.isDark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => setState(() => _longPressing = true),
      onLongPressEnd: (_) => setState(() => _longPressing = false),
      onLongPressCancel: () => setState(() => _longPressing = false),
      onHorizontalDragStart: (_) {
        setState(() {
          _dragging = true;
          _lastScrubIndex = null;
        });
      },
      onHorizontalDragUpdate: (d) =>
          _indexAt(d.globalPosition, mode: _IndicatorSeekMode.scrub),
      onHorizontalDragEnd: (_) {
        setState(() {
          _dragging = false;
          _lastScrubIndex = null;
        });
      },
      onHorizontalDragCancel: () => setState(() => _dragging = false),
      onTapUp: (d) {
        _lastScrubIndex = null;
        _indexAt(d.globalPosition, mode: _IndicatorSeekMode.tap);
      },
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: _kChromePadding,
          decoration: BoxDecoration(
            color: _chrome ? fillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(Sizes.size32),
            border: Border.all(
              color: _chrome ? borderColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: SizedBox(
            height: _kHitHeight,
            child: Center(child: widget.indicator),
          ),
        ),
      ),
    );
  }
}
