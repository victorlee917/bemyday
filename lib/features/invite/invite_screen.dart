import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/dropdown_button.dart' as common;
import 'package:bemyday/common/widgets/sheet/sheet_weekday_picker.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/invite/providers/invitation_provider.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart'
    show extractGradientColorsAsHex, InviteSheetBody;
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, this.selectedWeekdayIndex});
  static const routeName = "invite";
  static const routeUrl = "/invite";

  final int? selectedWeekdayIndex;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  int? _overriddenWeekdayIndex;

  void _onCloseTap() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onWeekdayChanged(int index) {
    setState(() => _overriddenWeekdayIndex = index);
  }

  void _showWeekdayPicker() async {
    final groups = await ref.read(currentUserGroupsProvider.future);
    if (!context.mounted) return;
    final groupIds = groups.map((g) => g.id).toList();
    final counts = groupIds.isNotEmpty
        ? await ref.read(groupRepositoryProvider).getGroupMemberCounts(groupIds)
        : <String, int>{};
    if (!context.mounted) return;
    showWeekdayPicker(
      context: context,
      items: buildWeekdayPickerItems(groups, memberCounts: counts),
      onWeekdaySelected: _onWeekdayChanged,
    );
  }

  Future<void> _onInviteTap() async {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
    final profile = ref.read(currentProfileProvider).valueOrNull;
    final preferredIndex =
        _overriddenWeekdayIndex ?? widget.selectedWeekdayIndex;
    final effectiveIndex = await ref.read(
      effectiveInviteWeekdayIndexProvider(preferredIndex).future,
    );
    final group = groupForWeekday(groups, effectiveIndex);
    final dbWeekday = effectiveIndex + 1;

    List<String>? gradientColors;
    if (profile?.avatarUrl != null) {
      gradientColors = await extractGradientColorsAsHex(profile!.avatarUrl!);
    }

    String token;
    try {
      token = await ref
          .read(invitationRepositoryProvider)
          .createInvitation(
            groupId: group?.id,
            dbWeekday: dbWeekday,
            gradientColors: gradientColors,
          );
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        showAppSnackBar(context, l10n.inviteCreateFailed(e.toString()));
      }
      return;
    }

    if (!context.mounted) return;
    final inviteUrl = 'https://bemyday.app/invitation/$token';
    final nickname = profile?.nickname ?? '?';
    final size = MediaQuery.sizeOf(context);
    final shareOrigin = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 10,
      height: 10,
    );
    final l10n = AppLocalizations.of(context)!;
    await Share.share(
      l10n.inviteShareMessage(nickname, inviteUrl),
      subject: l10n.inviteShareSubject,
      sharePositionOrigin: shareOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preferredIndex =
        _overriddenWeekdayIndex ?? widget.selectedWeekdayIndex;
    final effectiveAsync = ref.watch(
      effectiveInviteWeekdayIndexProvider(preferredIndex),
    );
    final groups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];
    final effectiveIndex = effectiveAsync.valueOrNull ?? 0;
    final group = groupForWeekday(groups, effectiveIndex);
    final memberCountAsync = group != null
        ? ref.watch(groupMemberCountProvider(group.id))
        : null;

    final isAlreadyFull =
        memberCountAsync?.valueOrNull != null &&
        memberCountAsync!.valueOrNull! >= 8;

    final profileAsync = ref.watch(currentProfileProvider);
    final inviterNickname = profileAsync.valueOrNull?.nickname ?? '?';
    final inviterAvatarUrl = profileAsync.valueOrNull?.avatarUrl;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: Scaffold(
        backgroundColor: isDarkMode(context)
            ? CustomColors.sheetColorDark
            : CustomColors.sheetColorLight,
        appBar: AppBar(
          title: Text(l10n.inviteScreenTitle),
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode(context)
              ? CustomColors.sheetColorDark
              : CustomColors.sheetColorLight,
          actions: [CloseAppBarButton(onTap: _onCloseTap)],
        ),
        body: Column(
          children: [
            Gaps.v24,
            Expanded(
              child: Center(
                child: InviteSheetBody(
                  weekdayName: weekdays[effectiveIndex].name,
                  inviterNickname: inviterNickname,
                  inviterAvatarUrl: inviterAvatarUrl,
                ),
              ),
            ),
            Gaps.v24,
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: Paddings.scaffoldH,
              right: Paddings.scaffoldH,
              bottom: Paddings.scaffoldV,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                common.DropdownButton(
                  label: weekdays[effectiveIndex].name,
                  onTap: _showWeekdayPicker,
                ),
                Gaps.v16,
                GestureDetector(
                  onTap: isAlreadyFull ? null : _onInviteTap,
                  child: Opacity(
                    opacity: isAlreadyFull ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      height: Sizes.size48,
                      decoration: BoxDecoration(
                        color: isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        borderRadius: BorderRadius.circular(RValues.button),
                      ),
                      child: Center(
                        child: Text(
                          isAlreadyFull
                              ? l10n.inviteAlreadyFull
                              : l10n.inviteShareInvitation,
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                color: isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
