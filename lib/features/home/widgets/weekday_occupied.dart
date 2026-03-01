import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
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
    final displayNameAsync = ref.watch(groupDisplayNameProvider(group));

    return Padding(
      padding: EdgeInsetsGeometry.only(top: Paddings.profileV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _onAvatarTap(context),
            child: Column(
              children: [
                displayNameAsync.when(
                  data: (displayName) => Column(
                    children: [
                      AvatarDefault(nickname: displayName),
                      CustomSizes.profileBSpacing,
                      Text(
                        "$displayName is\nMy ${weekdays[weekdayIndex].name}",
                        style: GoogleFonts.darumadropOne(
                          textStyle: TextStyle(
                            fontSize: Sizes.size32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  loading: () => Column(
                    children: [
                      AvatarDefault(nickname: '…'),
                      CustomSizes.profileBSpacing,
                      Text(
                        "… is\nMy ${weekdays[weekdayIndex].name}",
                        style: GoogleFonts.darumadropOne(
                          textStyle: TextStyle(
                            fontSize: Sizes.size32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  error: (_, __) => Column(
                    children: [
                      AvatarDefault(nickname: 'My Day'),
                      CustomSizes.profileBSpacing,
                      Text(
                        "My Day is\nMy ${weekdays[weekdayIndex].name}",
                        style: GoogleFonts.darumadropOne(
                          textStyle: TextStyle(
                            fontSize: Sizes.size32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gaps.v16,
          Opacity(opacity: 0.3, child: Text("Week ${groupWeekNumber(group)}")),
          Gaps.v12,
          TimeleftChip(targetWeekday: group.weekday),
          Gaps.v24,
          Expanded(
            child: Center(
              child: ref
                  .watch(hasCurrentWeekPostsProvider(group))
                  .when(
                    data: (hasPosts) => hasPosts
                        ? PostStack()
                        : PostEmpty(weekdayIndex: weekdayIndex),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => PostEmpty(weekdayIndex: weekdayIndex),
                  ),
            ),
          ),
          Gaps.v20,
          MoreButton(group: group),
          Gaps.v6,
        ],
      ),
    );
  }
}
