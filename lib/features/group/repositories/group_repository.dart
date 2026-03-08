import 'package:bemyday/features/group/models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 그룹 API - Supabase groups 테이블 연동
class GroupRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 로그인 유저가 속한 그룹 목록 조회
  ///
  /// - owner이거나 group_members에 있는 그룹 (속한 그룹)
  /// - RPC get_user_groups 사용
  Future<List<Group>> getCurrentUserGroups() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client.rpc('get_user_groups');

    return (response as List)
        .map((e) => Group.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 그룹 멤버 아바타 정보 (avatar_url, nickname)
  ///
  /// - [다른 멤버..., 현재 유저] 순. RPC get_group_members_ordered가 서버 auth.uid()로 정렬.
  Future<List<({String? avatarUrl, String nickname})>> getGroupMemberAvatars(
      String groupId) async {
    final rows = await _client.rpc(
      'get_group_members_ordered',
      params: {'p_group_id': groupId},
    ) as List;

    return rows.map((e) {
      final map = e as Map;
      return (
        avatarUrl: map['avatar_url'] as String?,
        nickname: (map['nickname'] as String?)?.trim() ?? '',
      );
    }).where((e) => e.nickname.isNotEmpty).toList();
  }

  /// 그룹 멤버 닉네임 목록 (group.name fallback용)
  ///
  /// - [다른 멤버..., 현재 유저] 순. RPC get_group_members_ordered가 서버 auth.uid()로 정렬.
  Future<List<String>> getGroupMemberNicknames(String groupId) async {
    final rows = await _client.rpc(
      'get_group_members_ordered',
      params: {'p_group_id': groupId},
    ) as List;

    return rows
        .map((e) => (e as Map)['nickname'] as String?)
        .whereType<String>()
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// 그룹 탈퇴 (현재 유저를 group_members에서 삭제)
  ///
  /// - 삭제 후 남은 멤버가 2명 이상이면 successor_id를 owner 다음 가입자로 갱신
  /// - 마지막 멤버 탈퇴 시 successor 갱신 안 함
  Future<void> leaveGroup(String groupId) async {
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

  /// 여러 그룹의 멤버 수를 한 번의 쿼리로 조회 (SECURITY DEFINER RPC로 RLS 우회)
  Future<Map<String, int>> getGroupMemberCounts(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};

    final rows = await _client.rpc(
      'get_group_member_counts',
      params: {'p_group_ids': groupIds},
    ) as List;

    final counts = <String, int>{};
    for (final g in groupIds) {
      counts[g] = 0;
    }
    for (final row in rows) {
      final map = row as Map;
      final gid = map['group_id'] as String?;
      final cnt = map['member_count'] as int? ?? 0;
      if (gid != null) {
        counts[gid] = cnt;
      }
    }
    return counts;
  }
}
