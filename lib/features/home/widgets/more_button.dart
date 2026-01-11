import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.size6,
        vertical: Sizes.size4,
      ),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(Sizes.size32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Icons.circle, size: Sizes.size4, color: Colors.white),
          Icon(Icons.circle, size: Sizes.size4, color: Colors.white),
          Icon(Icons.circle, size: Sizes.size4, color: Colors.white),
        ],
      ),
    );
  }
}
