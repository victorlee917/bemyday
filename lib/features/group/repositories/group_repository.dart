import 'package:bemyday/data/test_groups.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 그룹 API - Supabase groups 테이블 연동
class GroupRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 로그인 유저가 속한 그룹 목록 조회
  ///
  /// - Debug 빌드: 테스트 데이터 반환 (내 계정 기준)
  /// - owner이거나 group_members에 있는 그룹 (속한 그룹)
  /// - RPC get_user_groups 사용
  Future<List<Group>> getCurrentUserGroups() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    if (kDebugMode) {
      return createTestGroups(userId);
    }

    final response = await _client.rpc('get_user_groups');

    return (response as List)
        .map((e) => Group.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 그룹 멤버 아바타 정보 (avatar_url, nickname)
  ///
  /// - [다른 멤버..., 현재 유저] 순. 최대 6개까지 사용 권장
  /// - Debug + 테스트 그룹: avatar_url null, nickname만 반환
  Future<List<({String? avatarUrl, String nickname})>> getGroupMemberAvatars(
      String groupId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    if (kDebugMode && groupId.startsWith('test-')) {
      final others = getTestGroupOtherMemberNicknames(groupId);
      final profile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', currentUserId)
          .maybeSingle();
      final ownerNickname =
          (profile?['nickname'] as String?)?.trim();
      final name = ownerNickname?.isNotEmpty == true ? ownerNickname! : 'My Day';
      final list = others.isNotEmpty ? [...others, name] : [name];
      return list.map((n) => (avatarUrl: null, nickname: n)).toList();
    }

    final members = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final userIds =
        (members as List).map((e) => (e as Map)['user_id'] as String).toList();

    if (userIds.isEmpty) return [];

    final profiles = await _client
        .from('profiles')
        .select('id, nickname, avatar_url')
        .inFilter('id', userIds);

    final idToProfile = <String, ({String? avatarUrl, String nickname})>{};
    for (final e in profiles as List) {
      final map = e as Map;
      final id = map['id'] as String?;
      final n = (map['nickname'] as String?)?.trim() ?? '';
      final url = map['avatar_url'] as String?;
      if (id != null && n.isNotEmpty) {
        idToProfile[id] = (avatarUrl: url, nickname: n);
      }
    }

    final others = <({String? avatarUrl, String nickname})>[];
    ({String? avatarUrl, String nickname})? currentUser;
    for (final uid in userIds) {
      final p = idToProfile[uid];
      if (p == null) continue;
      if (uid == currentUserId) {
        currentUser = p;
      } else {
        others.add(p);
      }
    }

    if (currentUser != null) {
      return [...others, currentUser];
    }
    return others;
  }

  /// 그룹 멤버 닉네임 목록 (group.name fallback용)
  ///
  /// - [다른 멤버..., 현재 유저] 순으로 정렬. 표시 시 .first로 다른 멤버 우선
  /// - 현재 유저만 있으면 currentUser 닉네임이 표시됨
  /// - Debug + 테스트 그룹: mock 다른 멤버 + 현재 유저 프로필을 마지막에
  Future<List<String>> getGroupMemberNicknames(String groupId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    if (kDebugMode && groupId.startsWith('test-')) {
      final others = getTestGroupOtherMemberNicknames(groupId);
      final profile = await _client
          .from('profiles')
          .select('nickname')
          .eq('id', currentUserId)
          .maybeSingle();
      final currentUserNickname =
          (profile?['nickname'] as String?)?.trim();
      final ownerNickname = currentUserNickname?.isNotEmpty == true
          ? currentUserNickname!
          : 'My Day';
      // [다른 멤버..., owner] 순 (실제 그룹과 동일)
      return others.isNotEmpty ? [...others, ownerNickname] : [ownerNickname];
    }

    final members = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final userIds =
        (members as List).map((e) => (e as Map)['user_id'] as String).toList();

    if (userIds.isEmpty) return [];

    final profiles = await _client
        .from('profiles')
        .select('id, nickname')
        .inFilter('id', userIds);

    final idToNickname = <String, String>{};
    for (final e in profiles as List) {
      final map = e as Map;
      final id = map['id'] as String?;
      final n = map['nickname'] as String? ?? '';
      if (id != null && n.isNotEmpty) idToNickname[id] = n;
    }

    final others = <String>[];
    String? currentUserNickname;
    for (final uid in userIds) {
      final n = idToNickname[uid];
      if (n == null || n.isEmpty) continue;
      if (uid == currentUserId) {
        currentUserNickname = n;
      } else {
        others.add(n);
      }
    }

    // [다른 멤버..., 현재 유저] 순
    if (currentUserNickname != null) {
      return [...others, currentUserNickname];
    }
    return others;
  }

  /// 그룹 탈퇴 (현재 유저를 group_members에서 삭제)
  ///
  /// - 삭제 후 남은 멤버가 2명 이상이면 successor_id를 owner 다음 가입자로 갱신
  /// - 마지막 멤버 탈퇴 시 successor 갱신 안 함
  Future<void> leaveGroup(String groupId) async {
    if (kDebugMode && groupId.startsWith('test-')) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);

    final remaining = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);

    final rows = remaining as List;
    final newSuccessorId = rows.length >= 2
        ? (rows[1] as Map)['user_id'] as String
        : null;

    await _client
        .from('groups')
        .update({'successor_id': newSuccessorId})
        .eq('id', groupId);
  }

  /// 그룹 이름 업데이트
  Future<void> updateGroupName(String groupId, String name) async {
    if (kDebugMode && groupId.startsWith('test-')) return;

    await _client
        .from('groups')
        .update({'name': name.trim().isEmpty ? null : name.trim()})
        .eq('id', groupId);
  }

  /// 그룹 멤버 수
  Future<int> getGroupMemberCount(String groupId) async {
    final counts = await getGroupMemberCounts([groupId]);
    return counts[groupId] ?? 0;
  }

  /// 여러 그룹의 멤버 수를 한 번의 쿼리로 조회 (N+1 방지)
  Future<Map<String, int>> getGroupMemberCounts(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};

    if (kDebugMode && groupIds.any((id) => id.startsWith('test-'))) {
      final result = <String, int>{};
      for (final id in groupIds) {
        if (id.startsWith('test-')) {
          final others = getTestGroupOtherMemberNicknames(id);
          result[id] = 1 + others.length;
        }
      }
      return result;
    }

    final members = await _client
        .from('group_members')
        .select('group_id')
        .inFilter('group_id', groupIds);

    final counts = <String, int>{};
    for (final g in groupIds) {
      counts[g] = 0;
    }
    for (final row in members as List) {
      final gid = (row as Map)['group_id'] as String?;
      if (gid != null) {
        counts[gid] = (counts[gid] ?? 0) + 1;
      }
    }
    return counts;
  }
}
