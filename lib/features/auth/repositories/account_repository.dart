import 'package:supabase_flutter/supabase_flutter.dart';

/// 계정 삭제 관련 API
class AccountRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 계정 삭제
  ///
  /// 1. prepare_user_deletion RPC: 그룹 승계/삭제, 게시글·좋아요 삭제
  /// 2. Edge Function: auth.admin.deleteUser 호출
  /// 3. signOut: 로컬 세션 정리
  Future<void> deleteAccount() async {
    await _client.rpc('prepare_user_deletion');

    final session = _client.auth.currentSession;
    if (session == null) return;

    final response = await _client.functions.invoke(
      'delete-user-account',
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to delete account');
    }

    await _client.auth.signOut();
  }
}
