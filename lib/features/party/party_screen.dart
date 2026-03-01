import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/stat/stats_collection.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/party/party_detail_screen.dart';
import 'package:bemyday/features/party/widgets/week_section.dart';
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
    final group = widget.group;
    final weeks = group != null ? groupWeekNumber(group) : 0;
    final streaks = group?.streak ?? 0;
    final posts = group?.postCount ?? 0;

    final memberNicknamesAsync =
        group != null ? ref.watch(groupMemberNicknamesProvider(group.id)) : null;

    final info = groupDisplayInfo(group, memberNicknamesAsync?.valueOrNull);
    final displayText = info.subTitle ?? info.nickname;
    final title = group != null
        ? weekdays[group.weekday - 1].name
        : 'Monday';

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
        actions: [
          CloseAppBarButton(onTap: _onCloseTap),
        ],
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
                    child: AvatarDefault(
                      nickname: displayText.isNotEmpty
                          ? displayText.substring(0, 1)
                          : "?",
                    ),
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
                          ? CustomColors.clickableAreaDark
                          : CustomColors.clickableAreaLight,
                      borderRadius: BorderRadius.circular(RValues.island),
                    ),
                    child: StatsCollection(
                      stats: [
                        StatItem(title: "Weeks", value: weeks),
                        StatItem(title: "Streaks", value: streaks),
                        StatItem(title: "Posts", value: posts),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gaps.v24,
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) =>
                  WeekSection(week: weeks),
              separatorBuilder: (context, index) =>
                  SizedBox(height: CustomSizes.sectionGap),
              itemCount: 5,
            ),
          ],
        ),
      ),
    );
  }
}
