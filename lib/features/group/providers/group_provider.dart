import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/repositories/group_repository.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

/// 로그인 유저가 속한 그룹 목록
///
/// - ref.watch(currentUserGroupsProvider)로 사용
/// - ref.invalidate(currentUserGroupsProvider)로 새로고침
final currentUserGroupsProvider = FutureProvider<List<Group>>((ref) async {
  return ref.read(groupRepositoryProvider).getCurrentUserGroups();
});

/// 초대 가능한 요일 중 오늘과 가장 가까운 weekdayIndex (0~6)
/// 초대 가능 = 해당 요일에 그룹 없음 OR 그룹 있으나 멤버 1명 이하
final defaultInviteWeekdayIndexProvider = FutureProvider<int>((ref) async {
  return ref.watch(effectiveInviteWeekdayIndexProvider(null).future);
});

/// 여러 그룹의 멤버 수를 한 번의 API 호출로 조회 (N+1 방지)
final groupMemberCountsProvider =
    FutureProvider.family<Map<String, int>, List<String>>((ref, groupIds) async {
  if (groupIds.isEmpty) return {};
  return ref.read(groupRepositoryProvider).getGroupMemberCounts(groupIds);
});

/// 초대 화면에서 사용할 효과적인 weekdayIndex (0~6)
/// preferredIndex가 초대 가능하면 사용, 아니면 초대 가능한 요일 중 가장 가까운 요일
final effectiveInviteWeekdayIndexProvider =
    FutureProvider.family<int, int?>((ref, preferredIndex) async {
  final groups = await ref.watch(currentUserGroupsProvider.future);

  final groupIdsToCheck = <String>[];
  for (var dbWeekday = 1; dbWeekday <= 7; dbWeekday++) {
    final group = groupForWeekday(groups, dbWeekday - 1);
    if (group != null) {
      groupIdsToCheck.add(group.id);
    }
  }

  final counts = groupIdsToCheck.isNotEmpty
      ? await ref.read(groupMemberCountsProvider(groupIdsToCheck).future)
      : <String, int>{};

  final invitableWeekdays = <int>[];
  for (var dbWeekday = 1; dbWeekday <= 7; dbWeekday++) {
    final group = groupForWeekday(groups, dbWeekday - 1);
    if (group == null) {
      invitableWeekdays.add(dbWeekday);
    } else {
      final count = counts[group.id] ?? 0;
      if (count <= 1) invitableWeekdays.add(dbWeekday);
    }
  }

  return effectiveInviteWeekdayIndexFromInvitable(
    invitableWeekdays,
    preferredIndex,
  );
});

/// 그룹 멤버 수
final groupMemberCountProvider =
    FutureProvider.family<int, String>((ref, groupId) async {
  return ref.read(groupRepositoryProvider).getGroupMemberCount(groupId);
});

/// 그룹 멤버 닉네임 목록 (쉼표 구분 표시용)
final groupMemberNicknamesProvider =
    FutureProvider.family<List<String>, String>((ref, groupId) async {
  return ref.read(groupRepositoryProvider).getGroupMemberNicknames(groupId);
});

/// 그룹 멤버 아바타 정보 (avatar_url, nickname) - AvatarBubble용
final groupMemberAvatarsProvider =
    FutureProvider.family<List<({String? avatarUrl, String nickname})>, String>(
        (ref, groupId) async {
  return ref.read(groupRepositoryProvider).getGroupMemberAvatars(groupId);
});

/// 그룹 표시명 (group.name ?? 첫 멤버 닉네임)
///
/// currentUserGroupsProvider를 watch하여 DB 업데이트 시 자동 갱신
final groupDisplayNameProvider =
    FutureProvider.family<String, String>((ref, groupId) async {
  final groups = await ref.watch(currentUserGroupsProvider.future);
  final group = groups.where((g) => g.id == groupId).firstOrNull;
  if (group != null && group.name != null && group.name!.trim().isNotEmpty) {
    return group.name!.trim();
  }
  final nicknames =
      await ref.read(groupMemberNicknamesProvider(groupId).future);
  return nicknames.isNotEmpty ? nicknames.first : 'My Day';
});

/// 그룹 첫 멤버 프로필 사진 URL
///
/// groupDisplayNameProvider와 독립적이므로 이름 변경 시 깜빡이지 않음
final groupFirstAvatarProvider =
    FutureProvider.family<String?, String>((ref, groupId) async {
  final avatars =
      await ref.read(groupMemberAvatarsProvider(groupId).future);
  return avatars.isNotEmpty ? avatars.first.avatarUrl : null;
});
