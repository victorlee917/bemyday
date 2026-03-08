import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';

/// 요일 피커용 아이템 (weekdayIndex, group)
class WeekdayPickerItem {
  const WeekdayPickerItem({
    required this.weekdayIndex,
    this.subTitle,
    this.group,
    this.memberCount,
  });

  final int weekdayIndex;
  final String? subTitle;
  final Group? group;

  /// invite 모드 dimmed 판단용. null이면 provider에서 조회
  final int? memberCount;

  Weekday get weekday => weekdays[weekdayIndex];
}

/// 요일 피커용 WeekdayPickerItem 목록 생성
///
/// [postingOnly]: true면 참여 그룹이 있는 요일만 반환
/// [memberCounts]: invite 모드 dimmed 판단용. group.id → 멤버 수
List<WeekdayPickerItem> buildWeekdayPickerItems(
  List<Group> groups, {
  bool postingOnly = false,
  Map<String, int>? memberCounts,
}) {
  final items = weekdays.asMap().entries.map((e) {
    final group = groupForWeekday(groups, e.key);
    final count = group != null && memberCounts != null
        ? memberCounts[group.id]
        : null;
    return WeekdayPickerItem(
      weekdayIndex: e.key,
      group: group,
      memberCount: count,
    );
  });
  if (postingOnly) {
    return items.where((i) => i.group != null).toList();
  }
  return items.toList();
}

/// [다른 멤버..., 현재 유저] 순으로 정렬된 멤버 리스트에서 현재 유저 제외
List<String> memberNicknamesExcludingCurrent(List<String> rawNicknames) {
  if (rawNicknames.length <= 1) return [];
  return rawNicknames.sublist(0, rawNicknames.length - 1);
}

/// 그룹 표시용 nickname(avatar/이니셜용), subTitle(멤버 목록 표시)
///
/// - group.name 있으면: nickname=subTitle=group.name
/// - group.name 없으면: nickname=첫 멤버, subTitle=멤버(현재유저 제외) join
({String nickname, String? subTitle}) groupDisplayInfo(
  Group? group,
  List<String>? rawMemberNicknames,
) {
  if (group == null) return (nickname: '?', subTitle: null);
  final raw = rawMemberNicknames ?? [];
  final others = memberNicknamesExcludingCurrent(raw);
  final hasName = group.name?.trim().isNotEmpty == true;
  if (hasName) {
    final name = group.name!.trim();
    return (nickname: name, subTitle: name);
  }
  return (
    nickname: raw.isNotEmpty ? raw.first : '?',
    subTitle: others.isNotEmpty ? others.join(", ") : null,
  );
}

/// weekdayIndex(0~6)에 해당하는 그룹 조회
Group? groupForWeekday(List<Group> groups, int weekdayIndex) {
  final dbWeekday = weekdayIndex + 1;
  final match = groups.where((g) => g.weekday == dbWeekday);
  return match.isEmpty ? null : match.first;
}

/// 포스팅용 effective weekdayIndex
/// passedIndex가 유효(그룹 있음)하면 사용, 아니면 soonest
int effectivePostingWeekdayIndex(List<Group> groups, int? passedIndex) {
  if (groups.isEmpty) return (DateTime.now().weekday - 1) % 7;
  final hasGroup =
      passedIndex != null && groups.any((g) => g.weekday == passedIndex + 1);
  return (passedIndex != null && hasGroup)
      ? passedIndex
      : computeSoonestWeekdayIndex(groups);
}

/// {targetWeekday} 마감 시각 = 다음 요일 00:00 (TimeleftChip과 동일)
DateTime boundaryForWeekday(int targetWeekday) {
  final boundary = targetWeekday == 7 ? 1 : targetWeekday + 1;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysToAdd = (boundary - now.weekday + 7) % 7;
  final next = today.add(Duration(days: daysToAdd));
  return daysToAdd == 0 ? next.add(const Duration(days: 7)) : next;
}

/// 초대 가능한 요일(dbWeekday 1~7)과 preferredIndex로 effective weekdayIndex (0~6) 계산
///
/// - preferredIndex가 invitableWeekdays에 있으면 사용
/// - 없으면 invitableWeekdays 중 soonest(다음 도래) 반환
int effectiveInviteWeekdayIndexFromInvitable(
  List<int> invitableWeekdays,
  int? preferredIndex,
) {
  if (invitableWeekdays.isEmpty) {
    return (DateTime.now().weekday - 1) % 7;
  }
  if (preferredIndex != null) {
    final preferredDb = preferredIndex + 1;
    if (invitableWeekdays.contains(preferredDb)) {
      return preferredIndex;
    }
  }
  final now = DateTime.now();
  int? soonestDbWeekday;
  Duration minRemaining = Duration.zero;
  for (final dbWeekday in invitableWeekdays) {
    final next = boundaryForWeekday(dbWeekday);
    final remaining = next.difference(now);
    if (soonestDbWeekday == null || remaining < minRemaining) {
      soonestDbWeekday = dbWeekday;
      minRemaining = remaining;
    }
  }
  return (soonestDbWeekday! - 1) % 7;
}

/// 그룹 중 도래까지 시간이 가장 적게 남은 요일의 weekdayIndex (0~6)
/// groups가 비어있으면 당일 요일
int computeSoonestWeekdayIndex(List<Group> groups) {
  if (groups.isEmpty) {
    return (DateTime.now().weekday - 1) % 7;
  }
  final now = DateTime.now();
  Group? soonest;
  Duration minRemaining = Duration.zero;

  for (final g in groups) {
    final next = boundaryForWeekday(g.weekday);
    final remaining = next.difference(now);
    if (soonest == null || remaining < minRemaining) {
      soonest = g;
      minRemaining = remaining;
    }
  }
  return (soonest!.weekday - 1) % 7;
}

/// 이번 주차에서 대상 요일이 아직 도래하지 않았는지 여부.
///
/// true → 아직 해당 요일이 오지 않음 (다른 유저의 포스트 blur 처리 대상).
/// 현재 주차가 아닌 경우(과거 주차)는 항상 false (이미 공개됨).
bool isCurrentWeekBeforeReveal(Group group, {int? viewingWeekIndex}) {
  final currentWeek = groupWeekNumber(group);
  if ((viewingWeekIndex ?? currentWeek) != currentWeek) return false;
  return DateTime.now().weekday != group.weekday;
}

/// 그룹별 주차: 생성 후 해당 요일이 몇 번 도래했는지
///
/// - 첫 번째 {요일}이 끝나기 전: Week 1
/// - 첫 번째 {요일}이 끝난 뒤 ~ 두 번째 {요일}이 끝나기 전: Week 2
///
/// "첫 번째 {요일}"은 생성일 당일 또는 이후 가장 가까운 해당 요일.
/// 경계는 해당 요일의 다음 날 00:00 (예: 월요일 그룹 → 화요일 00:00).
int groupWeekNumber(Group group) {
  final now = DateTime.now();
  final createdAt = group.createdAt.toLocal();
  final targetWeekday = group.weekday; // 1=Mon ~ 7=Sun

  final createDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final daysToFirst = (targetWeekday - createdAt.weekday + 7) % 7;
  final firstOccurrence = createDate.add(Duration(days: daysToFirst));
  final firstBoundary = firstOccurrence.add(const Duration(days: 1));

  final nowDate = DateTime(now.year, now.month, now.day);
  if (nowDate.isBefore(firstBoundary)) return 1;

  final daysSinceBoundary = nowDate.difference(firstBoundary).inDays;
  return 2 + (daysSinceBoundary ~/ 7);
}
