import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 사용자 차단 API - Supabase user_blocks 테이블 연동
class BlockRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 사용자 차단
  Future<void> blockUser(String blockedId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    await _client.from('user_blocks').insert({
      'blocker_id': userId,
      'blocked_id': blockedId,
    });
  }

  /// 사용자 차단 해제
  Future<void> unblockUser(String blockedId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedId);
  }

  /// 차단한 사용자 ID 목록 조회
  Future<List<String>> getBlockedUserIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);

    return (rows as List).map((r) => r['blocked_id'] as String).toList();
  }

  /// 특정 사용자를 차단했는지 확인
  Future<bool> isBlocked(String blockedId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final rows = await _client
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }
}
