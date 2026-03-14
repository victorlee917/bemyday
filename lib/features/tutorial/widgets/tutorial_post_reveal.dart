import 'dart:async';
import 'dart:ui';

import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

const _mockWeekday = 'Monday';
const _mockWeek = 14;
const _countdownSeconds = 3;
const _blurOutDuration = Duration(milliseconds: 500);

/// 튜토리얼 3번째 페이지용. 3초 카운트다운 후 블러 페이드아웃.
class TutorialPostReveal extends StatefulWidget {
  const TutorialPostReveal({super.key});

  @override
  State<TutorialPostReveal> createState() => _TutorialPostRevealState();
}

class _TutorialPostRevealState extends State<TutorialPostReveal>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = _countdownSeconds;
  Timer? _timer;
  late AnimationController _blurOutController;
  late Animation<double> _blurOutOpacity;

  @override
  void initState() {
    super.initState();
    _blurOutController = AnimationController(
      vsync: this,
      duration: _blurOutDuration,
    );
    _blurOutOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _blurOutController, curve: Curves.easeOut),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining == 0) _blurOutController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blurOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderWidth = 5.0;
    return AspectRatio(
      aspectRatio: ARatio.common,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RValues.island),
          border: Border.all(
            width: borderWidth,
            color: isDarkMode(context)
                ? CustomColors.borderDark
                : CustomColors.borderLight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RValues.island - borderWidth),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: Transform.scale(
                    scale: 1.15,
                    child: Image.asset(
                      'assets/mockups/posts/post5.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _blurOutOpacity,
                builder: (context, _) {
                  if (_blurOutOpacity.value <= 0)
                    return const SizedBox.shrink();
                  return Positioned.fill(
                    child: ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: Opacity(
                        opacity: _blurOutOpacity.value,
                        child: ImageFiltered(
                          imageFilter: Blurs.stackOverlay,
                          child: Transform.scale(
                            scale: 1.15,
                            child: Image.asset(
                              'assets/mockups/posts/post5.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _blurOutOpacity,
                builder: (context, _) {
                  if (_blurOutOpacity.value <= 0)
                    return const SizedBox.shrink();
                  return Center(
                    child: Opacity(
                      opacity: _blurOutOpacity.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: 0.7,
                            child: Text(
                              AppLocalizations.of(context)!.revealsIn,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Sizes.size14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Gaps.v8,
                          Text(
                            '${_secondsRemaining}s',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Sizes.size24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(Paddings.scaffoldH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mockWeekday,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Sizes.size14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Week $_mockWeek',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: Sizes.size12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
