import 'package:bemyday/common/widgets/async_value_builder.dart';
import 'package:bemyday/common/widgets/vacant_page.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/friends/widgets/weekday_section.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, required this.bottomPadding});
  static const routeName = "friends";
  static const routeUrl = "/friends";
  final double bottomPadding;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  void _onInviteTap() {
    showInviteSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(currentUserGroupsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Weekdays"),
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsets.only(left: Paddings.scaffoldH),
          child: GestureDetector(
            onTap: _onInviteTap,
            child: Center(
              child: FaIcon(FontAwesomeIcons.circlePlus, size: Sizes.size20),
            ),
          ),
        ),
      ),
      body: AsyncValueBuilder<List<Group>>(
        value: groupsAsync,
        data: (groups) {
          if (groups.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: widget.bottomPadding,
                top: Paddings.profileV,
              ),
              child: VacantPage(
                message: "Invite friends to get started",
                onInviteTap: _onInviteTap,
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(
              bottom: widget.bottomPadding,
              top: Paddings.scaffoldV,
              left: Paddings.scaffoldH,
              right: Paddings.scaffoldH,
            ),
            itemBuilder: (context, index) {
              final group = groups[index];
              final weekday = weekdays[group.weekday - 1];
              return WeekdaySection(
                weekday: weekday,
                weekdayIndex: group.weekday - 1,
                group: group,
              );
            },
            separatorBuilder: (context, index) =>
                SizedBox(height: CustomSizes.sectionGap),
            itemCount: groups.length,
          );
        },
      ),
    );
  }
}
