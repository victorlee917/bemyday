import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/common/widgets/sheet/sheet_widget.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// invite: 초대 화면용 (canInvite, dimmed 등)
/// posting: 포스팅 화면용 (참여 그룹만, group.name / 멤버 닉네임 표시)
enum WeekdayPickerDisplayMode { invite, posting }

class SheetWeekdayPicker extends ConsumerWidget {
  const SheetWeekdayPicker({
    super.key,
    required this.items,
    required this.onWeekdaySelected,
    this.isDarkOnly = false,
    this.displayMode = WeekdayPickerDisplayMode.invite,
  });

  final List<WeekdayPickerItem> items;
  final ValueChanged<int> onWeekdaySelected;
  final bool isDarkOnly;
  final WeekdayPickerDisplayMode displayMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetSelect(
      isDarkOnly: isDarkOnly,
      items: items.map((item) {
        return displayMode == WeekdayPickerDisplayMode.posting
            ? _PostingWeekdayPickerRow(
                item: item,
                onWeekdaySelected: onWeekdaySelected,
                isDarkOnly: isDarkOnly,
              )
            : _WeekdayPickerRow(
                item: item,
                onWeekdaySelected: onWeekdaySelected,
                isDarkOnly: isDarkOnly,
              );
      }).toList(),
    );
  }
}

/// 포스팅용: 참여 그룹만, title=weekday.name, subTitle=group.name or 멤버(현재유저제외), nickname=group.name or 첫멤버
class _PostingWeekdayPickerRow extends ConsumerWidget {
  const _PostingWeekdayPickerRow({
    required this.item,
    required this.onWeekdaySelected,
    required this.isDarkOnly,
  });

  final WeekdayPickerItem item;
  final ValueChanged<int> onWeekdaySelected;
  final bool isDarkOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.group == null) return const SizedBox.shrink();

    final group = item.group!;
    final memberNicknamesAsync =
        ref.watch(groupMemberNicknamesProvider(group.id));
    final info = groupDisplayInfo(group, memberNicknamesAsync.valueOrNull);

    return SheetWidget(
      left: Row(
        children: [
          AvatarPackage(
            nickname: info.nickname,
            title: item.weekday.name,
            subTitle: info.subTitle,
            isDarkOnly: isDarkOnly,
          ),
        ],
      ),
      onTap: () => onWeekdaySelected(item.weekdayIndex),
      isDarkOnly: isDarkOnly,
    );
  }
}

/// 한 요일 행: canInvite(멤버 0~1명) vs dimmed(멤버 2명+)
class _WeekdayPickerRow extends ConsumerWidget {
  const _WeekdayPickerRow({
    required this.item,
    required this.onWeekdaySelected,
    required this.isDarkOnly,
  });

  final WeekdayPickerItem item;
  final ValueChanged<int> onWeekdaySelected;
  final bool isDarkOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCountAsync = item.group != null
        ? ref.watch(groupMemberCountProvider(item.group!.id))
        : null;

    final isDimmed = memberCountAsync?.valueOrNull != null &&
        memberCountAsync!.valueOrNull! >= 2;

    final canInvite = item.group == null ||
        (memberCountAsync?.valueOrNull ?? 0) < 2;

    final subTitle = canInvite
        ? 'Can Invite'
        : (item.subTitle != null
            ? item.subTitle
            : null);

    return SheetWidget(
      left: Row(
        children: [
          item.group == null
              ? AvatarPackage(
                  nickname: item.weekday.shortestName,
                  title: item.weekday.name,
                  subTitle: subTitle ?? 'Can Invite',
                  isDarkOnly: isDarkOnly,
                )
              : _GroupAvatarPackage(
                  item: item,
                  isDarkOnly: isDarkOnly,
                  forceSubTitle: canInvite ? 'Can Invite' : null,
                  isDimmed: isDimmed,
                ),
        ],
      ),
      onTap: () => onWeekdaySelected(item.weekdayIndex),
      isDarkOnly: isDarkOnly,
      isDimmed: isDimmed,
    );
  }
}

class _GroupAvatarPackage extends ConsumerWidget {
  const _GroupAvatarPackage({
    required this.item,
    required this.isDarkOnly,
    this.forceSubTitle,
    this.isDimmed = false,
  });

  final WeekdayPickerItem item;
  final bool isDarkOnly;
  final String? forceSubTitle;
  final bool isDimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = item.group!;
    final memberNicknamesAsync = ref.watch(groupMemberNicknamesProvider(group.id));

    final raw = memberNicknamesAsync.valueOrNull;
    final others = raw != null ? memberNicknamesExcludingCurrent(raw) : null;
    final groupOrNicknames = group.name?.trim().isNotEmpty == true
        ? group.name!.trim()
        : others != null && others.isNotEmpty
            ? others.join(", ")
            : memberNicknamesAsync.isLoading
                ? '…'
                : null;

    final subTitle = forceSubTitle ??
        item.subTitle ??
        (isDimmed
            ? (groupOrNicknames != null
                ? 'Already Full | $groupOrNicknames'
                : 'Already Full')
            : groupOrNicknames);

    final displayText = subTitle ?? item.weekday.name;

    return AvatarPackage(
      nickname: displayText.isNotEmpty
          ? displayText.substring(0, 1).toLowerCase()
          : item.weekday.shortestName,
      title: item.weekday.name,
      subTitle: subTitle,
      isDarkOnly: isDarkOnly,
    );
  }
}

void showWeekdayPicker({
  required BuildContext context,
  required List<WeekdayPickerItem> items,
  required ValueChanged<int> onWeekdaySelected,
  bool isDarkOnly = false,
  WeekdayPickerDisplayMode displayMode = WeekdayPickerDisplayMode.invite,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SheetWeekdayPicker(
      items: items,
      onWeekdaySelected: onWeekdaySelected,
      isDarkOnly: isDarkOnly,
      displayMode: displayMode,
    ),
  );
}
