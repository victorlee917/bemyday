import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

/// 정방형 영역 안에 멤버별 독립 원형 아바타를 배치.
///
/// 각 아바타는 [AvatarDefault]를 사용.
/// - 1명: 전체 크기 원 1개
/// - 2명: 동일 크기, 좌상단/우하단 겹침
/// - 3명: 동일 크기, 첫 번째는 1/4·2/4 분면(상단), 나머지 둘은 3/4·4/4 분면(하단) 겹침
/// - 4명: 2×2 그리드
/// - 5명+: 3개 + "+N" 원 (2×2)
class AvatarDividedCircle extends StatelessWidget {
  const AvatarDividedCircle({
    super.key,
    required this.members,
    required this.diameter,
    this.gap = 2.0,
    this.borderColor,
  });

  final List<({String? avatarUrl, String nickname})> members;
  final double diameter;
  final double gap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return AvatarDefault(
        nickname: '?',
        radius: diameter / 2,
        borderColor: borderColor,
      );
    }

    if (members.length == 1) {
      final m = members.first;
      return AvatarDefault(
        nickname: m.nickname,
        avatarUrl: m.avatarUrl,
        radius: diameter / 2,
        borderColor: borderColor,
      );
    }

    final displayMembers = members.length > 4 ? members.sublist(0, 3) : members;
    final surplus = members.length > 4 ? members.length - 3 : 0;
    final total = displayMembers.length + (surplus > 0 ? 1 : 0);
    // AvatarDefault 테두리(Widths.devider)로 인한 오버플로우 방지
    final borderInset = Widths.devider * 4;
    final cellSize = (diameter - gap - borderInset) / 2;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: _buildLayout(displayMembers, surplus, total, cellSize),
    );
  }

  Widget _buildLayout(
    List<({String? avatarUrl, String nickname})> display,
    int surplus,
    int total,
    double cellSize,
  ) {
    final r = cellSize / 2;

    Widget avatar(int i) => AvatarDefault(
      nickname: display[i].nickname,
      avatarUrl: display[i].avatarUrl,
      radius: r,
      borderColor: borderColor,
    );

    switch (total) {
      case 2:
        return _buildTwoOverlapping(display, diameter);
      case 3:
        return _buildThreeOverlapping(display, diameter);
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                avatar(0),
                SizedBox(width: gap),
                avatar(1),
              ],
            ),
            SizedBox(height: gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                avatar(2),
                SizedBox(width: gap),
                surplus > 0 ? _surplusCircle(surplus, cellSize) : avatar(3),
              ],
            ),
          ],
        );
    }
  }

  /// 2명: 동일 크기 아바타를 좌상단/우하단에 배치, 서로 겹침
  Widget _buildTwoOverlapping(
    List<({String? avatarUrl, String nickname})> display,
    double diameter,
  ) {
    // 겹침이 되도록 크기 설정 (각 아바타가 컨테이너의 ~70%)
    final r = diameter * 0.3;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          child: AvatarDefault(
            nickname: display[1].nickname,
            avatarUrl: display[1].avatarUrl,
            radius: r,
            borderColor: borderColor,
            borderWidth: Widths.devider * 2,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: AvatarDefault(
            nickname: display[0].nickname,
            avatarUrl: display[0].avatarUrl,
            radius: r,
            borderColor: borderColor,
            borderWidth: Widths.devider * 2,
          ),
        ),
      ],
    );
  }

  /// 3명: 동일 크기 아바타, 첫 번째는 1/4·2/4 분면 사이(상단), 나머지 둘은 3/4·4/4 분면(하단)에 겹침
  Widget _buildThreeOverlapping(
    List<({String? avatarUrl, String nickname})> display,
    double diameter,
  ) {
    final r = diameter * 0.3;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          child: AvatarDefault(
            nickname: display[2].nickname,
            avatarUrl: display[2].avatarUrl,
            radius: r,
            borderColor: borderColor,
            borderWidth: Widths.devider * 2,
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: AvatarDefault(
            nickname: display[1].nickname,
            avatarUrl: display[1].avatarUrl,
            radius: r,
            borderColor: borderColor,
            borderWidth: Widths.devider * 2,
          ),
        ),
        Positioned(
          left: diameter / 2 - r,
          top: 0,
          child: AvatarDefault(
            nickname: display[0].nickname,
            avatarUrl: display[0].avatarUrl,
            radius: r,
            borderColor: borderColor,
            borderWidth: Widths.devider * 2,
          ),
        ),
      ],
    );
  }

  Widget _surplusCircle(int surplus, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.grey.shade400,
          child: Center(
            child: Text(
              '+$surplus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
