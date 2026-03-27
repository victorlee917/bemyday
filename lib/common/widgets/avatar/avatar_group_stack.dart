import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/avatar/avatar_divided_circle.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 그룹 멤버 아바타를 하나의 원 안에 분할 표시.
///
/// - 그룹에 [현재 유저만] 있으면: 그 유저(본인) 아바타를 표시.
/// - [다른 멤버가 한 명이라도] 있으면: currentUser는 제외하고 나머지만 표시.
///
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
    final memberCountAsync = ref.watch(groupMemberCountProvider(groupId));
    final membersAsync = ref.watch(groupMembersOrderedProvider(groupId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final borderColor = showBorder
        ? (isDarkMode(context)
            ? CustomColors.borderDark
            : CustomColors.borderLight)
        : null;

    if (groupId.isEmpty) {
      return AvatarDefault(
        nickname: '…',
        radius: radius,
        borderColor: borderColor,
        loading: true,
      );
    }

    return memberCountAsync.when(
      data: (memberCount) => membersAsync.when(
        data: (members) {
          final excludeSelf = memberCount > 1;
          final chosen = excludeSelf && currentUserId != null
              ? members.where((m) => m.userId != currentUserId).toList()
              : members;
          final display = chosen
              .map((e) => (avatarUrl: e.avatarUrl, nickname: e.nickname))
              .toList();

          return AvatarDividedCircle(
            members: display,
            diameter: radius * 2,
            borderColor: borderColor,
          );
        },
        loading: () => AvatarDefault(
            nickname: '…',
            radius: radius,
            borderColor: borderColor,
            loading: true),
        error: (_, __) =>
            AvatarDefault(nickname: '?', radius: radius, borderColor: borderColor),
      ),
      loading: () => AvatarDefault(
          nickname: '…', radius: radius, borderColor: borderColor, loading: true),
      error: (_, __) =>
          AvatarDefault(nickname: '?', radius: radius, borderColor: borderColor),
    );
  }
}

