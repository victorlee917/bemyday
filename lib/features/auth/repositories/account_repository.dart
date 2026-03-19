import 'package:supabase_flutter/supabase_flutter.dart';

/// 계정 삭제 관련 API
class AccountRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 계정 삭제
  ///
  /// Edge Function에서 prepare_user_deletion RPC → storage 정리 → auth.admin.deleteUser 수행.
  /// (클라이언트에서 RPC 먼저 호출하면 프로필 삭제 후 401 Invalid JWT 발생 가능)
  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final response = await _client.functions.invoke(
      'delete-user-account',
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      final msg = response.data is Map
          ? (response.data as Map)['error'] as String?
          : null;
      throw Exception(msg ?? 'Failed to delete account');
    }

    await _client.auth.signOut();
  }
}
