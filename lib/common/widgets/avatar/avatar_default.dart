import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AvatarDefault extends StatelessWidget {
  const AvatarDefault({
    super.key,
    this.radius = CustomSizes.avatarDefault,
    required this.nickname,
    this.avatarUrl,
    this.borderColor,
  });

  final double radius;
  final String nickname;

  /// 프로필 사진 URL (Supabase Storage 등). 있으면 이미지로 표시, 없으면 닉네임 이니셜
  final String? avatarUrl;

  /// 테두리 색상. null이면 테두리 없음.
  final Color? borderColor;

  String _getFirstChar(String text) {
    if (text.isEmpty) return '';
    return text.characters.first;
  }

  Widget _wrapBorder(Widget child, BuildContext context) {
    final color =
        borderColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? CustomColors.borderDark
            : CustomColors.borderLight);
    return Container(
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(color: color, width: Widths.devider),
        ),
      ),
      child: child,
    );
  }

  Widget _buildInitialChild(BuildContext context) {
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
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
          context,
        );
      },
      placeholder: (context, url) => _wrapBorder(
        CircleAvatar(
          radius: radius,
          child: Text(
            _getFirstChar(nickname),
            style: TextStyle(fontSize: radius * 0.8),
          ),
        ),
        context,
      ),
      errorWidget: (context, url, error) => _wrapBorder(
        CircleAvatar(
          radius: radius,
          child: Text(
            _getFirstChar(nickname),
            style: TextStyle(fontSize: radius * 0.8),
          ),
        ),
        context,
      ),
    );
  }
}
