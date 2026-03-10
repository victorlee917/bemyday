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
    final avatarUrl =
        ref.watch(groupFirstAvatarProvider(group.id)).valueOrNull;
    final info = groupDisplayInfo(group, memberNicknamesAsync.valueOrNull);

    return SheetWidget(
      left: Row(
        children: [
          AvatarPackage(
            nickname: info.nickname,
            avatarUrl: avatarUrl,
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
///
/// 참여 그룹 존재 && 멤버 2명 이상(currentUser 포함) → dimmed, 초대 불가
///
/// item.memberCount가 있으면 사용 (invite 시 build 시점에 주입), 없으면 provider watch
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
    final int? count;
    if (item.memberCount != null) {
      count = item.memberCount;
    } else if (item.group != null) {
      count = ref.watch(groupMemberCountProvider(item.group!.id)).valueOrNull;
    } else {
      count = null;
    }

    final isDimmed = count != null && count >= 8;

    final canInvite = item.group == null || (count ?? 0) < 8;
    final childTitle = canInvite ? null : 'Already Full';

    return SheetWidget(
      left: Row(
        children: [
          item.group == null
              ? AvatarPackage(
                  nickname: item.weekday.name,
                  title: item.weekday.name,
                  childTitle: childTitle,
                  subTitle: 'Vacant',
                  isDarkOnly: isDarkOnly,
                )
              : _GroupAvatarPackage(
                  item: item,
                  isDarkOnly: isDarkOnly,
                  childTitle: childTitle,
                  memberCount: count ?? 0,
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
    required this.childTitle,
    required this.memberCount,
    this.isDimmed = false,
  });

  final WeekdayPickerItem item;
  final bool isDarkOnly;
  final String? childTitle;
  final int memberCount;
  final bool isDimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = item.group!;
    final memberAvatarsAsync = ref.watch(groupMemberAvatarsProvider(group.id));
    final memberNicknamesAsync =
        ref.watch(groupMemberNicknamesProvider(group.id));

    final avatars = memberAvatarsAsync.valueOrNull;
    final firstAvatarUrl = avatars != null && avatars.isNotEmpty
        ? avatars.first.avatarUrl
        : null;
    final firstNickname = avatars != null && avatars.isNotEmpty
        ? avatars.first.nickname
        : item.weekday.name;

    final String subTitle;
    if (memberCount == 0) {
      subTitle = 'Vacant';
    } else {
      final hasGroupName = group.name?.trim().isNotEmpty == true;
      if (hasGroupName) {
        subTitle = group.name!.trim();
      } else {
        final nicknames = memberNicknamesAsync.valueOrNull;
        subTitle = nicknames != null && nicknames.isNotEmpty
            ? nicknames.join(', ')
            : '…';
      }
    }

    return AvatarPackage(
      nickname: firstNickname,
      avatarUrl: firstAvatarUrl,
      title: item.weekday.name,
      childTitle: childTitle,
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
