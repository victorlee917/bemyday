import 'dart:math';

import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/home/widgets/post_empty.dart';
import 'package:bemyday/features/home/widgets/post_stack.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// [get_group_members_ordered] 순서: [다른 멤버…, 현재 유저]. 이름 없을 때만 peers 중 하나.
/// [shuffleEpoch]는 해당 요일 페이지에 다시 들어올 때마다 올려 다른 멤버가 나오게 함.
String _headlineDisplayName(
  Group group,
  List<String> orderedNicknames,
  int shuffleEpoch,
) {
  final named = group.name?.trim();
  if (named != null && named.isNotEmpty) return named;

  if (orderedNicknames.isEmpty) return '…';
  if (orderedNicknames.length < 2) return orderedNicknames.first;

  final others =
      orderedNicknames.sublist(0, orderedNicknames.length - 1);
  final seed = Object.hash(
    group.id.hashCode,
    shuffleEpoch,
    Object.hashAll(others),
  );
  return others[Random(seed).nextInt(others.length)];
}

class WeekdayOccupied extends ConsumerWidget {
  const WeekdayOccupied({
    super.key,
    required this.weekdayIndex,
    required this.group,
    required this.shuffleEpoch,
  });

  final int weekdayIndex;
  final Group group;

  /// [HomeScreen]에서 해당 요일로 스와이프해 들어올 때마다 증가.
  final int shuffleEpoch;

  void _onAvatarTap(BuildContext context) {
    context.push(PartyScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref
        .watch(groupMemberNicknamesProvider(group.id))
        .when(
          data: (nicks) => _headlineDisplayName(group, nicks, shuffleEpoch),
          loading: () => group.name?.trim().isNotEmpty == true
              ? group.name!.trim()
              : '…',
          error: (_, __) => '…',
        );

    return Padding(
      padding: EdgeInsetsGeometry.only(top: Paddings.profileV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _onAvatarTap(context),
            child: Column(
              children: [
                AvatarGroupStack(groupId: group.id),
                CustomSizes.profileBSpacing,
                Text(
                  "$displayName is\nMy ${weekdays[weekdayIndex].name}",
                  style: GoogleFonts.darumadropOne(
                    textStyle: TextStyle(
                      fontSize: Sizes.size28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Gaps.v20,
          TimeleftChip(targetWeekday: group.weekday),
          Gaps.v16,
          Expanded(
            child: Center(
              child: ref
                  .watch(hasCurrentWeekPostsProvider(group))
                  .when(
                    data: (hasPosts) => hasPosts
                        ? PostStack(group: group)
                        : PostEmpty(weekdayIndex: weekdayIndex),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => PostEmpty(weekdayIndex: weekdayIndex),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
