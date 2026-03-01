import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// 초대 URL 베이스 (딥링크)
const String inviteUrlBase = 'https://bemyday.app/invite';

/// [Repository] 초대 API - Supabase invitations 테이블 연동
///
/// - group_id 있음: 해당 요일 그룹이 이미 있을 때
/// - group_id 없음: 해당 요일 그룹이 없을 때 (승낙 시 그룹 생성)
class InvitationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// URL-safe 토큰 생성 (12자)
  String _generateToken() {
    final bytes = List<int>.generate(9, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// 초대 생성
  ///
  /// - [groupId]: 해당 요일 그룹이 있으면 전달, 없으면 null
  /// - [dbWeekday]: 1=월 ~ 7=일 (group_id 없을 때 필수)
  /// - 만료: 1시간
  /// - Returns: 생성된 token
  Future<String> createInvitation({
    String? groupId,
    required int dbWeekday,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    String token;
    do {
      token = _generateToken();
      final existing = await _client
          .from('invitations')
          .select('id')
          .eq('token', token)
          .maybeSingle();
      if (existing == null) break;
    } while (true);

    final expiresAt =
        DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();

    final row = <String, dynamic>{
      'token': token,
      'inviter_id': userId,
      'expires_at': expiresAt,
      'metadata': metadata ?? {},
    };

    if (groupId != null) {
      row['group_id'] = groupId;
    } else {
      row['weekday'] = dbWeekday;
    }

    await _client.from('invitations').insert(row);
    return token;
  }

  /// 토큰으로 초대 정보 조회 (딥링크/OG용)
  Future<Map<String, dynamic>?> getInvitationByToken(String token) async {
    final response = await _client.rpc(
      'get_invitation_by_token',
      params: {'invite_token': token},
    );
    if (response == null) return null;
    return response as Map<String, dynamic>;
  }

  /// 초대 승낙 (그룹 참여)
  ///
  /// - group_id 있으면 기존 그룹에 추가
  /// - group_id 없으면 그룹 생성 후 inviter + accepter 추가
  Future<String> acceptInvitation(String token) async {
    final response = await _client.rpc(
      'join_group_by_invite_token',
      params: {'invite_token': token},
    );
    if (response == null) throw Exception('초대 처리에 실패했습니다');
    final map = response as Map<String, dynamic>;
    final groupId = map['group_id'] as String?;
    if (groupId == null) throw Exception('그룹 정보를 가져올 수 없습니다');
    return groupId;
  }
}
