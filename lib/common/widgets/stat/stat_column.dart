import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class StatColumn extends StatelessWidget {
  const StatColumn({super.key, required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.5,
            child: Text(title, style: TextStyle(fontSize: Sizes.size12)),
          ),
          Gaps.v2,
          Text(
            "$value",
            style: TextStyle(
              fontSize: Sizes.size16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
