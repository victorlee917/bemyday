import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/common/widgets/stat/stats_collection.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({super.key, required this.weekday, this.group});

  final String weekday;
  final Group? group;

  void _onCardTap(BuildContext context) {
    context.push(PartyScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final weeks = group != null ? groupWeekNumber(group!) : 0;
    final streaks = group?.streak ?? 0;
    final posts = group?.postCount ?? 0;

    final memberNicknamesAsync = group != null
        ? ref.watch(groupMemberNicknamesProvider(group!.id))
        : null;
    final memberCountAsync = group != null
        ? ref.watch(groupMemberCountProvider(group!.id))
        : null;

    final info = groupDisplayInfo(group, memberNicknamesAsync?.valueOrNull);
    final displayText = group == null
        ? weekday
        : (info.subTitle ?? info.nickname);
    final memberCount = memberCountAsync?.valueOrNull ?? 0;
    final subTitle = memberCount == 1
        ? '1 member'
        : memberCount == 0
        ? '0 members'
        : '$memberCount members';

    return GestureDetector(
      onTap: () => _onCardTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.size16,
          vertical: Sizes.size16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode(context)
              ? CustomColors.clickableAreaDark
              : CustomColors.clickableAreaLight,
          borderRadius: BorderRadius.circular(RValues.island),
          border: Border.all(
            color: isDarkMode(context)
                ? CustomColors.borderDark
                : CustomColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AvatarPackage(
                  nickname: displayText.isNotEmpty
                      ? displayText.substring(0, 1).toLowerCase()
                      : '?',
                  title: displayText,
                  avatarWidget: group != null
                      ? AvatarGroupStack(
                          groupId: group!.id,
                          radius: CustomSizes.avatarComment,
                        )
                      : null,
                  subTitle: memberCountAsync?.isLoading == true
                      ? '…'
                      : subTitle,
                ),
              ],
            ),
            Gaps.v16,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: StatsCollection(
                    stats: [
                      StatItem(title: l10n.statWeeks, value: weeks),
                      StatItem(title: l10n.statStreaks, value: streaks),
                      StatItem(title: l10n.statPosts, value: posts),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
