import 'dart:async';

import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class RevealCountdown extends StatefulWidget {
  const RevealCountdown({super.key, required this.targetWeekday});

  /// 1=Mon ~ 7=Sun
  final int targetWeekday;

  @override
  State<RevealCountdown> createState() => _RevealCountdownState();
}

class _RevealCountdownState extends State<RevealCountdown> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysToTarget = (widget.targetWeekday - now.weekday + 7) % 7;
    final target = daysToTarget == 0
        ? today.add(const Duration(days: 7))
        : today.add(Duration(days: daysToTarget));
    setState(() {
      _remaining = target.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: 0.7,
          child: Text(
            "Reveals in",
            style: TextStyle(
              color: Colors.white,
              fontSize: Sizes.size14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatCountdown(_remaining),
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizes.size24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
