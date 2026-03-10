import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum AvatarShape { circle, squircle }

class AvatarDefault extends StatelessWidget {
  const AvatarDefault({
    super.key,
    this.radius = CustomSizes.avatarDefault,
    required this.nickname,
    this.avatarUrl,
    this.borderColor,
    this.borderWidth,
    this.shape = AvatarShape.circle,
  });

  final double radius;
  final String nickname;
  final AvatarShape shape;

  /// 프로필 사진 URL (Supabase Storage 등). 있으면 이미지로 표시, 없으면 닉네임 이니셜
  final String? avatarUrl;

  /// 테두리 색상. null이면 테두리 없음.
  final Color? borderColor;

  /// 테두리 두께. null이면 [Widths.devider] 사용.
  final double? borderWidth;

  String _getFirstChar(String text) {
    if (text.isEmpty) return '';
    return text.characters.first;
  }

  Widget _wrapBorder(Widget child, BuildContext context) {
    final color = borderColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? CustomColors.borderDark
            : CustomColors.borderLight);
    if (borderColor == null) return child;
    final width = borderWidth ?? Widths.devider;
    if (shape == AvatarShape.squircle) {
      final size = radius * 2;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius * 0.4),
          border: Border.all(color: color, width: width),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    return Container(
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(color: color, width: width),
        ),
      ),
      child: child,
    );
  }

  Widget _buildInitialChild(BuildContext context) {
    if (shape == AvatarShape.squircle) {
      final size = radius * 2;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            _getFirstChar(nickname),
            style: TextStyle(
              fontSize: radius * 0.8,
              color: isDarkMode(context) ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(
        _getFirstChar(nickname),
        style: TextStyle(
          fontSize: radius * 0.8,
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildImageChild(ImageProvider imageProvider) {
    if (shape == AvatarShape.squircle) {
      final size = radius * 2;
      return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius * 0.4),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(radius: radius, backgroundImage: imageProvider);
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    if (!hasAvatar) {
      return _wrapBorder(_buildInitialChild(context), context);
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageBuilder: (context, imageProvider) {
        return _wrapBorder(
          _buildImageChild(imageProvider),
          context,
        );
      },
      placeholder: (context, url) => _wrapBorder(
        _buildInitialChild(context),
        context,
      ),
      errorWidget: (context, url, error) => _wrapBorder(
        _buildInitialChild(context),
        context,
      ),
    );
  }
}
