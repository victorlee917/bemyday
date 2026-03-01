import 'package:bemyday/features/group/models/group.dart';

/// 테스트 그룹별 "다른 멤버" 닉네임 (group.name 없을 때 fallback)
///
/// 현재 유저 제외, 같은 그룹에 있는 다른 유저 느낌의 mock 데이터
/// owner 포함 2명 (other 1명)
const _testGroupOtherMemberNicknames = <String, List<String>>{
  'test-monday': ['Alice'],
  'test-wednesday': ['Bob'],
  'test-friday': ['Charlie'],
  'test-saturday': ['Diana'],
};

/// 로그인 유저 기준 테스트용 그룹 목록
///
/// Debug 빌드에서 Supabase 대신 사용. 월/수/금/토 요일 그룹 포함.
List<Group> createTestGroups(String ownerId) {
  final now = DateTime.now();
  return [
    Group(
      id: 'test-monday-${ownerId.substring(0, 8)}',
      ownerId: ownerId,
      weekday: 1,
      name: 'Work Buddies',
      weekBoundaryTimezone: 'Asia/Seoul',
      postCount: 12,
      streak: 3,
      streakUpdatedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 21)),
    ),
    Group(
      id: 'test-wednesday-${ownerId.substring(0, 8)}',
      ownerId: ownerId,
      weekday: 3,
      name: 'Midweek Crew',
      weekBoundaryTimezone: 'Asia/Seoul',
      postCount: 8,
      streak: 1,
      streakUpdatedAt: now,
      createdAt: now.subtract(const Duration(days: 14)),
    ),
    Group(
      id: 'test-friday-${ownerId.substring(0, 8)}',
      ownerId: ownerId,
      weekday: 5,
      weekBoundaryTimezone: 'Asia/Seoul',
      postCount: 5,
      streak: 0,
      createdAt: now.subtract(const Duration(days: 5)),
    ),
    Group(
      id: 'test-saturday-${ownerId.substring(0, 8)}',
      ownerId: ownerId,
      weekday: 6,
      name: 'Weekend Squad',
      weekBoundaryTimezone: 'Asia/Seoul',
      postCount: 24,
      streak: 7,
      streakUpdatedAt: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 49)),
    ),
  ];
}

/// 테스트 그룹의 다른 멤버 닉네임 (현재 유저 제외)
List<String> getTestGroupOtherMemberNicknames(String groupId) {
  for (final entry in _testGroupOtherMemberNicknames.entries) {
    if (groupId.startsWith(entry.key)) {
      return entry.value;
    }
  }
  return [];
}
