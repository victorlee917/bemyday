import 'dart:io';

import 'package:bemyday/features/profile/models/profile.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 프로필 API - Supabase profiles 테이블 연동
///
/// 닉네임 설정/수정, 프로필 조회, 아바타 업로드/삭제
class ProfileRepository {
  static const String _avatarsBucket = 'avatars';

  SupabaseClient get _client => Supabase.instance.client;

  /// 프로필 없으면 생성 (soft delete 후 재가입 등)
  Future<void> ensureProfile() async {
    await _client.rpc('ensure_profile', params: {});
  }

  /// 기기 timezone을 프로필에 동기화 (요일 언락 푸시의 그룹 기준 시간용)
  /// owner인 그룹 중 week_boundary_timezone이 UTC/미설정인 경우에도 업데이트
  Future<void> syncTimezoneToProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (tz.isEmpty) return;
      await _client.from('profiles').update({'timezone': tz}).eq('id', userId);
      await _client
          .from('groups')
          .update({'week_boundary_timezone': tz})
          .eq('owner_id', userId)
          .isFilter('week_boundary_timezone', null);
      await _client
          .from('groups')
          .update({'week_boundary_timezone': tz})
          .eq('owner_id', userId)
          .eq('week_boundary_timezone', 'UTC');
    } catch (_) {
      // timezone 조회/업데이트 실패 시 무시
    }
  }

  /// 프로필 조회 (닉네임, 프로필 사진)
  ///
  /// - [userId] 없으면 현재 로그인 유저
  /// - RLS: 모든 프로필 조회 가능
  Future<Profile?> getProfile({String? userId}) async {
    final targetId = userId ?? _client.auth.currentUser?.id;
    if (targetId == null) return null;

    final response = await _client
        .from('profiles')
        .select('id, nickname, avatar_url')
        .eq('id', targetId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// 닉네임 업데이트
  ///
  /// - 신규 가입자(기본 닉네임)와 기존 유저 모두 동일한 UPDATE 사용
  /// - DB nickname_format_check 제약으로 형식 검증
  /// - RLS: 본인 프로필만 수정 가능
  Future<void> updateNickname(String nickname) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다');
    }

    await _client
        .from('profiles')
        .update({'nickname': nickname.trim().toLowerCase()})
        .eq('id', userId);
  }

  /// 아바타 업로드
  ///
  /// - Storage avatars 버킷에 {userId}/avatar.jpg 경로로 업로드
  /// - profiles.avatar_url 업데이트
  /// - RLS: 본인 폴더에만 업로드 가능
  Future<String> uploadAvatar(File file) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다');
    }

    final path = '$userId/avatar.jpg';
    await _client.storage.from(_avatarsBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final baseUrl = _client.storage.from(_avatarsBucket).getPublicUrl(path);
    // 캐시 무효화: 같은 경로 덮어쓸 때 NetworkImage가 새 이미지를 가져오도록
    final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }

  /// 아바타 삭제
  ///
  /// - Storage에서 파일 삭제 후 profiles.avatar_url null 처리
  Future<void> deleteAvatar() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다');
    }

    final path = '$userId/avatar.jpg';
    try {
      await _client.storage.from(_avatarsBucket).remove([path]);
    } catch (_) {
      // 파일 없으면 무시
    }
    await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
  }
}
