import 'dart:ui';

import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

/// PostStack blur 오버레이용 공통 컨테이너.
/// GroupPostStackWithBlur, TutorialPostStackWithBlur에서 사용.
class BlurOverlayCard extends StatelessWidget {
  const BlurOverlayCard({
    super.key,
    required this.width,
    required this.height,
    required this.dark,
    required this.child,
  });

  final double width;
  final double height;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RValues.island),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RValues.island),
        child: BackdropFilter(
          filter: Blurs.stackOverlay,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: (dark
                      ? CustomColors.backgroundColorDark
                      : CustomColors.backgroundColorLight)
                  .withValues(alpha: 0.3),
              border: Border.all(
                color: dark ? CustomColors.borderDark : CustomColors.borderLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(RValues.island),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
