import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/avatar/avatar_divided_circle.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// currentUser를 제외한 그룹 멤버들의 아바타를 하나의 원 안에 분할 표시.
///
/// Provider에서 데이터를 가져와 [AvatarDividedCircle]에 위임.
/// [showBorder]가 true이면 다크/라이트 모드에 따라 테두리 표시.
class AvatarGroupStack extends ConsumerWidget {
  const AvatarGroupStack({
    super.key,
    required this.groupId,
    this.radius = CustomSizes.avatarDefault,
    this.showBorder = true,
  });

  final String groupId;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarsAsync = ref.watch(groupMemberAvatarsProvider(groupId));
    final borderColor = showBorder
        ? (isDarkMode(context)
            ? CustomColors.borderDark
            : CustomColors.borderLight)
        : null;

    return avatarsAsync.when(
      data: (avatars) {
        final others = avatars.length > 1
            ? avatars.sublist(0, avatars.length - 1)
            : avatars;

        return AvatarDividedCircle(
          members: others,
          diameter: radius * 2,
          borderColor: borderColor,
        );
      },
      loading: () => AvatarDefault(
          nickname: '…', radius: radius, borderColor: borderColor, loading: true),
      error: (_, __) =>
          AvatarDefault(nickname: '?', radius: radius, borderColor: borderColor),
    );
  }
}
