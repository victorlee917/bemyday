import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 신고 API - Supabase content_reports 테이블 연동
class ReportRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// 콘텐츠 또는 사용자 신고
  ///
  /// [targetType]: 'post', 'comment', 'user'
  /// [targetId]: 대상 ID
  /// [reason]: 'harassment', 'hate_speech', 'violence', 'sexual_content',
  ///           'spam', 'self_harm', 'impersonation', 'other'
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    await _client.from('content_reports').insert({
      'reporter_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      if (description != null) 'description': description,
    });
  }
}
