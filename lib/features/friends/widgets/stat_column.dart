import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class StatColumn extends StatelessWidget {
  const StatColumn({super.key, required this.title, required this.stat});

  final String title;
  final int stat;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: Sizes.size12)),
          Text(
            "$stat",
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
