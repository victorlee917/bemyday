import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostStack extends StatelessWidget {
  const PostStack({super.key});

  void _onPostTap(BuildContext context) {
    context.push(PostScreen.routeUrl);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onPostTap(context),
      child: Stack(
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
      ),
    );
  }
}
