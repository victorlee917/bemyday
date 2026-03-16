import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

/// 가로 겹침 아바타 스택 (WidgetStack 기반).
/// GroupPostStackWithBlur, TutorialPostStackWithBlur에서 사용.
class HorizontalAvatarStack extends StatelessWidget {
  const HorizontalAvatarStack({
    super.key,
    required this.members,
    required this.dark,
  });

  final List<({String? avatarUrl, String nickname})> members;
  final bool dark;

  static const _avatarSize = 50.0;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return SizedBox(
        height: _avatarSize,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 14,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }

    final borderColor = dark ? CustomColors.borderDark : CustomColors.borderLight;
    const borderWidth = 2.0;

    final avatarWidgets = members.map((m) {
      return Container(
        width: _avatarSize,
        height: _avatarSize,
        decoration: ShapeDecoration(
          shape: CircleBorder(
            side: BorderSide(color: borderColor, width: borderWidth),
          ),
        ),
        child: ClipOval(
          child: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
              ? CachedPostImage(
                  imageUrl: m.avatarUrl!,
                  fit: BoxFit.cover,
                  placeholderColor: dark
                      ? CustomColors.primaryColorDark
                      : CustomColors.primaryColorLight,
                )
              : ColoredBox(
                  color: dark
                      ? CustomColors.primaryColorDark
                      : CustomColors.primaryColorLight,
                  child: Center(
                    child: Text(
                      m.nickname.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: dark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ),
      );
    }).toList();

    final settings = RestrictedPositions(
      maxCoverage: 0.5,
      minCoverage: 0.4,
      align: StackAlign.center,
      laying: StackLaying.first,
    );

    return SizedBox(
      height: _avatarSize,
      width: _avatarSize * members.length.clamp(1, 5).toDouble(),
      child: WidgetStack(
        positions: settings,
        stackedWidgets: avatarWidgets,
        buildInfoWidget: (surplus, _) => Container(
          width: _avatarSize,
          height: _avatarSize,
          decoration: ShapeDecoration(
            color: Colors.grey.shade300,
            shape: CircleBorder(
              side: BorderSide(
                color: dark ? CustomColors.borderDark : CustomColors.borderLight,
                width: 1.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              '+$surplus',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
