import 'dart:io';
import 'dart:typed_data';

import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 포스트 API - Supabase posts 테이블 연동
class PostRepository {
  static const String _postsBucket = 'posts';

  /// 업로드 시 적용하는 압축 설정 (용량 절감)
  static const int _compressQuality = 85;
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1920;

  SupabaseClient get _client => Supabase.instance.client;

  /// 포스트 생성 (압축 후 Storage 업로드 + posts insert)
  ///
  /// - JPEG quality 85, 최대 1920px로 리사이즈 후 업로드
  /// - Storage 경로: {groupId}/{userId}_{timestamp}.jpg
  /// - Debug + 테스트 그룹: 스킵
  Future<void> createPost(Group group, File imageFile, {String? caption}) async {
    if (kDebugMode && group.id.startsWith('test-')) {
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: _maxWidth,
      minHeight: _maxHeight,
      quality: _compressQuality,
      format: CompressFormat.jpeg,
    );
    if (compressed == null || compressed.isEmpty) {
      throw Exception('이미지 압축 실패');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${group.id}/${userId}_$timestamp.jpg';

    await _client.storage.from(_postsBucket).uploadBinary(
          path,
          Uint8List.fromList(compressed),
          fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final photoUrl =
        _client.storage.from(_postsBucket).getPublicUrl(path);
    final weekIndex = groupWeekNumber(group);

    await _client.from('posts').insert({
      'group_id': group.id,
      'author_id': userId,
      'week_index': weekIndex,
      'photo_url': photoUrl,
      'caption': caption,
    });
  }

  /// 현재 week에 해당하는 포스트 존재 여부
  ///
  /// - Debug + 테스트 그룹: false (빈 상태 표시)
  Future<bool> hasCurrentWeekPosts(Group group) async {
    if (kDebugMode && group.id.startsWith('test-')) {
      return false;
    }

    final weekIndex = groupWeekNumber(group);
    final posts = await _client
        .from('posts')
        .select('id')
        .eq('group_id', group.id)
        .eq('week_index', weekIndex)
        .limit(1);

    return (posts as List).isNotEmpty;
  }
}
