import 'package:bemyday/common/widgets/async_value_builder.dart';
import 'package:bemyday/common/widgets/vacant_page.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/friends/widgets/group_post_stack_with_blur.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
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
    showInviteSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(currentUserGroupsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.friendsTabTitle),
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
                message: l10n.inviteFriendsToGetStarted,
                onInviteTap: _onInviteTap,
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(
              bottom: widget.bottomPadding,
              top: Paddings.scaffoldV,
              left: 0,
              right: 0,
            ),
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupPostStackWithBlur(
                group: group,
                weekdayIndex: group.weekday - 1,
              );
            },
            separatorBuilder: (context, index) =>
                SizedBox(height: Sizes.size32),
            itemCount: groups.length,
          );
        },
      ),
    );
  }
}
