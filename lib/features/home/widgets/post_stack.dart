import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class PostStack extends StatelessWidget {
  const PostStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FractionallySizedBox(
          heightFactor: 0.95,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue,
                border: BoxBorder.all(
                  color: Colors.white54,
                  width: Sizes.size10,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(radius: Sizes.size16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
