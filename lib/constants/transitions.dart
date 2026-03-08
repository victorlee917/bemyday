import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 화면 전환 애니메이션 duration
class TransitionDurations {
  /// 기본 화면 전환 (슬라이드 업)
  static const slideUp = Duration(milliseconds: 200);

  /// Hero 애니메이션
  static const hero = Duration(milliseconds: 300);

  /// 바텀시트
  static const bottomSheet = Duration(milliseconds: 200);

  /// 페이드 전환
  static const fade = Duration(milliseconds: 400);
}

/// 화면 전환 커브
class TransitionCurves {
  /// 기본 전환 커브
  static const standard = Curves.easeOutCubic;

  /// 바텀시트 커브
  static const bottomSheet = Curves.easeOut;

  /// Hero 애니메이션 커브
  static const hero = Curves.easeInOut;
}

/// 슬라이드 업 페이지 전환 생성
CustomTransitionPage<T> slideUpTransitionPage<T>({
  required Widget child,
  LocalKey? key,
  bool opaque = true,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    opaque: opaque,
    transitionDuration: TransitionDurations.slideUp,
    reverseTransitionDuration: TransitionDurations.slideUp,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: TransitionCurves.standard,
      );
      final position = Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curvedAnimation);
      return SlideTransition(position: position, child: child);
    },
  );
}

/// Hero 전용 페이지 라우트 생성
PageRouteBuilder<T> heroPageRoute<T>({required Widget child}) {
  return PageRouteBuilder<T>(
    transitionDuration: TransitionDurations.hero,
    reverseTransitionDuration: TransitionDurations.hero,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

CustomTransitionPage<T> fadeOutTransitionPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    transitionDuration: TransitionDurations.fade,
    child: child,
    transitionsBuilder: (context, animation, secondayAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<T> fadeOutScaleTransitionPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    transitionDuration: TransitionDurations.fade,
    child: child,
    transitionsBuilder: (context, animation, secondayAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      );
    },
  );
}
