import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/stat/stats_collection.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/party/party_detail_screen.dart';
import 'package:bemyday/features/party/widgets/week_grid_card.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key, this.group});

  final Group? group;
  static const routeName = "party";
  static const routeUrl = "/party";

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  void _onCloseTap() {
    context.pop();
  }

  void _onDetailTap() {
    context.push(PartyDetailScreen.routeUrl, extra: widget.group);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final group = widget.group;
    final weeks = group != null ? groupWeekNumber(group) : 0;
    final streaks = group?.streak ?? 0;
    final posts = group?.postCount ?? 0;

    final memberNicknamesAsync = group != null
        ? ref.watch(groupMemberNicknamesProvider(group.id))
        : null;
    final displayNameAsync = group != null
        ? ref.watch(groupDisplayNameProvider(group.id))
        : null;
    final info = groupDisplayInfo(group, memberNicknamesAsync?.valueOrNull);
    final displayText =
        displayNameAsync?.valueOrNull ?? info.subTitle ?? info.nickname;
    final title = group != null ? weekdays[group.weekday - 1].name : l10n.weekdayMonday;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsets.only(left: Paddings.scaffoldH),
          child: GestureDetector(
            onTap: _onDetailTap,
            child: Center(
              child: FaIcon(FontAwesomeIcons.circleInfo, size: Sizes.size20),
            ),
          ),
        ),
        actions: [CloseAppBarButton(onTap: _onCloseTap)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: Paddings.profileV),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: Paddings.scaffoldH,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _onDetailTap,
                    child: group != null
                        ? AvatarGroupStack(groupId: group.id)
                        : AvatarGroupStack(groupId: ''),
                  ),
                  CustomSizes.profileBSpacing,
                  GestureDetector(
                    onTap: _onDetailTap,
                    child: SizedBox(
                      width: 300,
                      child: Text(
                        displayText,
                        style: GoogleFonts.darumadropOne(
                          fontSize: Sizes.size28,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  Gaps.v24,
                  Container(
                    height: Sizes.size80,
                    decoration: BoxDecoration(
                      color: isDarkMode(context)
                          ? CustomColors.nonClickableAreaDark
                          : CustomColors.nonClickableAreaLight,
                      borderRadius: BorderRadius.circular(RValues.island),
                      border: Border.all(
                        color: isDarkMode(context)
                            ? CustomColors.borderDark
                            : CustomColors.borderLight,
                      ),
                    ),
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
            ),
            Gaps.v24,
            if (group != null) _buildWeekGrid(group, weeks),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + Sizes.size24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekGrid(Group group, int currentWeek) {
    final summariesAsync = ref.watch(weekPostSummariesProvider(group));

    return summariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => const SizedBox.shrink(),
      data: (summaries) {
        final currentSummary = summaries
            .where((s) => s.weekIndex == currentWeek)
            .firstOrNull;
        final pastWeeks = summaries
            .where((s) => s.weekIndex != currentWeek)
            .toList();

        final items = <WeekGridItem>[
          WeekGridItem(
            weekIndex: currentWeek,
            postCount: currentSummary?.postCount ?? 0,
            authorIds: currentSummary?.authorIds ?? [],
            latestPost: currentSummary?.latestPost,
            isCurrentWeek: true,
          ),
          for (final w in pastWeeks)
            WeekGridItem(
              weekIndex: w.weekIndex,
              postCount: w.postCount,
              authorIds: w.authorIds,
              latestPost: w.latestPost,
              isCurrentWeek: false,
            ),
        ];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisSpacing = 12.0;
              const mainAxisSpacing = 20.0;
              const labelHeight = 36.0;
              final cellWidth = (constraints.maxWidth - crossAxisSpacing) / 2;
              final cardHeight = cellWidth / ARatio.common;
              final cellHeight = cardHeight + labelHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: cellWidth / cellHeight,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return WeekGridCard(item: items[index], group: group);
                },
              );
            },
          ),
        );
      },
    );
  }
}
