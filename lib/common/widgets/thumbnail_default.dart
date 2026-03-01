import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class ThumbnailDefault extends StatelessWidget {
  const ThumbnailDefault({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadiusGeometry.circular(RValues.thumbnail),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: ARatio.common,
            child: Container(
              decoration: const BoxDecoration(color: Colors.blue),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: AvatarDefault(nickname: "Bogus", radius: Sizes.size16),
          ),
        ],
      ),
    );
  }
}
