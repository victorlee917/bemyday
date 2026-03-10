import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/home/widgets/more_button.dart';
import 'package:bemyday/features/home/widgets/post_empty.dart';
import 'package:bemyday/features/home/widgets/post_stack.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WeekdayOccupied extends ConsumerWidget {
  const WeekdayOccupied({
    super.key,
    required this.weekdayIndex,
    required this.group,
  });

  final int weekdayIndex;
  final Group group;

  void _onAvatarTap(BuildContext context) {
    context.push(PartyScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(groupDisplayNameProvider(group.id)).valueOrNull ?? '…';

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
          Gaps.v14,
          MoreButton(group: group),
        ],
      ),
    );
  }
}
