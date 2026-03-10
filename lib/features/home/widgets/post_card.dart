import 'dart:ui';
import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.borderColor,
    required this.bgColor,
    this.borderWidth = 5.0,
    this.blur = false,
  });

  final Post post;
  final Color borderColor;
  final Color bgColor;
  final double borderWidth;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(RValues.thumbnail),
        color: bgColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RValues.thumbnail - borderWidth),
        child: ImageFiltered(
          imageFilter: blur
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: CachedPostImage(
            imageUrl: post.photoUrl,
            cacheKey: post.storagePath,
            placeholderColor: bgColor,
          ),
        ),
      ),
    );
  }
}
