import 'package:flutter/material.dart';

/// 화면 상단 또는 하단에 은은한 검정 그래디언트를 적용하는 위젯.
///
/// [PostScreen] 등에서 이미지 위에 텍스트 가독성을 높이기 위해 사용.
class GradientOverlay extends StatelessWidget {
  const GradientOverlay({
    super.key,
    required this.height,
    this.alignment = Alignment.topCenter,
    this.opacity = 0.3,
  });

  /// 그래디언트가 차지할 높이.
  final double height;

  /// [Alignment.topCenter]이면 위에서 아래로, [Alignment.bottomCenter]이면 아래에서 위로 페이드.
  final Alignment alignment;

  /// 그래디언트의 불투명도 (0.0 ~ 1.0).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
