import 'package:bemyday/constants/styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AvatarDefault extends StatelessWidget {
  const AvatarDefault({
    super.key,
    this.radius = CustomSizes.avatarDefault,
    required this.nickname,
    this.avatarUrl,
  });

  final double radius;
  final String nickname;

  /// 프로필 사진 URL (Supabase Storage 등). 있으면 이미지로 표시, 없으면 닉네임 이니셜
  final String? avatarUrl;

  String _getFirstChar(String text) {
    if (text.isEmpty) return '';
    return text.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    if (!hasAvatar) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          _getFirstChar(nickname),
          style: TextStyle(fontSize: radius * 0.8),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        child: Text(
          _getFirstChar(nickname),
          style: TextStyle(fontSize: radius * 0.8),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        child: Text(
          _getFirstChar(nickname),
          style: TextStyle(fontSize: radius * 0.8),
        ),
      ),
    );
  }
}
