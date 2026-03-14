import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 포스트 이미지를 캐시하여 표시하는 공통 위젯.
///
/// [PostCard], [WeekGridCard], [PostScreen] 등에서 동일 패턴으로 사용되던
/// CachedNetworkImage + placeholder + errorWidget 조합을 통합.
class CachedPostImage extends StatelessWidget {
  const CachedPostImage({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.fit = BoxFit.cover,
    this.placeholderColor = Colors.black,
    this.errorWidget,
  });

  final String imageUrl;
  final String? cacheKey;
  final BoxFit fit;
  final Color placeholderColor;
  final Widget? errorWidget;

  static bool _isAssetPath(String url) => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? ColoredBox(color: placeholderColor),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => ColoredBox(color: placeholderColor),
      errorWidget: (_, __, ___) =>
          errorWidget ?? ColoredBox(color: placeholderColor),
    );
  }
}
