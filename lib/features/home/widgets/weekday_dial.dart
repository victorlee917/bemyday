import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppBar에 표시되는 요일 선택기 위젯
/// HomeScreen의 PageView 스와이프에 따라 자동으로 회전하며,
/// 중앙의 요일이 강조되고 양쪽으로 갈수록 작아지고 흐려지는 효과
class WeekdayDial extends StatefulWidget {
  const WeekdayDial({super.key, required this.weekdayIndex});
  final int weekdayIndex; // 현재 선택된 요일 인덱스 (0=월요일, 6=일요일)

  @override
  State<WeekdayDial> createState() => _WeekdayDialState();
}

class _WeekdayDialState extends State<WeekdayDial> {
  late final PageController _pageController; // 요일 페이지 스크롤을 제어
  final int _multiplier = 1000; // 무한 스크롤을 위한 배수 (충분히 큰 수)

  @override
  void initState() {
    super.initState();
    // 초기 페이지 계산: 중간 지점(7000) + 현재 요일 인덱스
    final initialPage = (_multiplier * 7) + widget.weekdayIndex;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.15, // 각 페이지가 화면의 15%만 차지 (여러 요일이 동시에 보임)
    );
  }

  /// 부모로부터 weekdayIndex가 변경되면 호출됨
  /// HomeScreen의 PageView 스와이프 시 자동으로 해당 요일로 회전
  @override
  void didUpdateWidget(WeekdayDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekdayIndex != widget.weekdayIndex) {
      _scrollToWeekday();
    }
  }

  /// 현재 페이지에서 목표 요일로 부드럽게 스크롤
  /// 가장 가까운 방향으로 이동 (예: 일요일→월요일은 +1칸, -6칸이 아님)
  void _scrollToWeekday() {
    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page?.round() ?? 0; // 현재 페이지 번호
    final currentWeekdayIndex = currentPage % 7; // 현재 요일 (0-6)
    final diff = (widget.weekdayIndex - currentWeekdayIndex) % 7; // 목표까지 거리
    // diff > 3이면 반대방향이 더 가까움 (예: 6→0은 +1이 -6보다 가까움)
    final targetPage =
        currentPage +
        (diff == 0
            ? 0
            : diff > 3
            ? diff - 7
            : diff);

    _pageController.animateToPage(
      targetPage,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: IgnorePointer(
        // 사용자의 터치 입력을 무시 (읽기 전용)
        child: PageView.builder(
          controller: _pageController,
          itemCount: _multiplier * 7 * 2, // 충분히 큰 수 (양방향 무한 스크롤)
          itemBuilder: (context, index) {
            final weekdayIndex = index % 7; // 0-6 사이의 요일 인덱스
            final weekday = weekdays[weekdayIndex]; // 요일 객체

            // PageController 변화에 따라 실시간으로 리빌드
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                // 초기 로드 시 haveDimensions가 false인 경우 initialPage로 계산해 플래시 방지
                final currentPage = _pageController.position.haveDimensions
                    ? (_pageController.page ?? 0)
                    : _pageController.initialPage.toDouble();
                final distance = (currentPage - index).abs();

                final value =
                    1.0 - (distance * 0.3).clamp(0.0, 1.0);
                final scale =
                    0.8 + (0.4 * (1.0 - distance.clamp(0.0, 1.0)));

                return Transform.scale(
                  scale: scale, // 크기 조정
                  child: Center(
                    child: Opacity(
                      opacity: value, // 투명도 조정
                      child: Text(
                        weekday.shortestName, // M, T, W, T, F, S, S
                        style: GoogleFonts.darumadropOne(
                          textStyle: TextStyle(
                            // 현재 선택된 요일은 검은색, 나머지는 회색
                            color: weekdayIndex == widget.weekdayIndex
                                ? isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black
                                : Colors.grey,
                            fontSize: Sizes.size16,
                            // 현재 선택된 요일은 볼드체
                            fontWeight: weekdayIndex == widget.weekdayIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
