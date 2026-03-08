import 'dart:async';

import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

/// {targetWeekday} 마감까지 남은 시간
///
/// - [targetWeekday]: 1=월 ~ 7=일
/// - 마감 시각 = 해당 요일이 끝나는 시점 = 다음 요일 00:00
///   (예: Friday 마감 = Saturday 00:00, 금요일 23:00이면 1h left)
/// - 24h 이상: D-1, D-2, ..., 24h 미만: Today
class TimeleftChip extends StatefulWidget {
  const TimeleftChip({super.key, required this.targetWeekday});

  final int targetWeekday;

  @override
  State<TimeleftChip> createState() => _TimeleftChipState();
}

class _TimeleftChipState extends State<TimeleftChip> {
  late String _text;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateText();
  }

  @override
  void didUpdateWidget(TimeleftChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetWeekday != widget.targetWeekday) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateText() {
    setState(() => _text = _formatTimeLeft(widget.targetWeekday));

    final next = _nextMidnight(_boundaryWeekday(widget.targetWeekday));
    final remaining = next.difference(DateTime.now());

    _timer?.cancel();
    final interval = remaining.inSeconds < 60
        ? const Duration(seconds: 1)
        : remaining.inSeconds < 3600
        ? const Duration(minutes: 1)
        : const Duration(hours: 1);
    _timer = Timer.periodic(interval, (_) {
      if (mounted) _updateText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size4,
      ),
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? CustomColors.nonClickableAreaDark
            : CustomColors.nonClickableAreaLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: Sizes.size1,
          color: isDarkMode(context)
              ? CustomColors.borderDark
              : CustomColors.borderLight,
        ),
      ),
      child: Text(_text, style: TextStyle(fontSize: Sizes.size10)),
    );
  }
}

/// {targetWeekday} 마감 시각 = (targetWeekday+1) 요일 00:00
int _boundaryWeekday(int targetWeekday) =>
    targetWeekday == 7 ? 1 : targetWeekday + 1;

/// 다음 {weekday} 00:00 시각 계산
DateTime _nextMidnight(int weekday) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysToAdd = (weekday - now.weekday + 7) % 7;
  final next = today.add(Duration(days: daysToAdd));
  return daysToAdd == 0 ? next.add(const Duration(days: 7)) : next;
}

String _formatTimeLeft(int targetWeekday) {
  final boundary = _boundaryWeekday(targetWeekday);
  final next = _nextMidnight(boundary);
  final remaining = next.difference(DateTime.now());

  if (remaining.isNegative) return 'Today';

  final secs = remaining.inSeconds;
  if (secs < 86400) return 'Today';
  return 'D-${secs ~/ 86400}';
}
