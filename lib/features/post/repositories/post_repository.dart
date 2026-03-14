import 'dart:io';
import 'dart:typed_data';

import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [Repository] 포스트 API - Supabase posts 테이블 연동
class PostRepository {
  static const String _postsBucket = 'posts';

  /// 업로드 시 적용하는 압축 설정 (용량 절감)
  static const int _compressQuality = 75;
  static const int _maxWidth = 1280;
  static const int _maxHeight = 1280;

  SupabaseClient get _client => Supabase.instance.client;

  /// 포스트 생성 (압축 후 Storage 업로드 + posts insert)
  ///
  /// - JPEG quality 75, 최대 1280px로 리사이즈 후 업로드
  /// - Storage 경로: {groupId}/{userId}_{timestamp}.jpg
  Future<void> createPost(Group group, File imageFile, {String? caption}) async {
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

    final weekIndex = groupWeekNumber(group);

    await _client.from('posts').insert({
      'group_id': group.id,
      'author_id': userId,
      'week_index': weekIndex,
      'photo_url': path,
      'caption': caption,
    });
  }

  /// 현재 week에 해당하는 포스트 존재 여부
  Future<bool> hasCurrentWeekPosts(Group group) async {
    final weekIndex = groupWeekNumber(group);
    final posts = await _client
        .from('posts')
        .select('id')
        .eq('group_id', group.id)
        .eq('week_index', weekIndex)
        .limit(1);

    return (posts as List).isNotEmpty;
  }

  /// Signed URL 만료 시간 (초) — 24시간
  static const int _signedUrlExpiry = 86400;

  /// 현재 week에 해당하는 포스트 목록 (created_at 오름차순)
  Future<List<Post>> getCurrentWeekPosts(Group group) async {
    return getPostsByWeek(group, groupWeekNumber(group));
  }

  /// 그룹의 최신 포스트 최대 [limit]개 (created_at 내림차순)
  Future<List<Post>> getLatestPosts(Group group, {int limit = 4}) async {
    final rows = await _client
        .from('posts')
        .select('id, group_id, author_id, week_index, photo_url, caption, created_at')
        .eq('group_id', group.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    final posts = (rows as List).map((r) => Post.fromJson(r)).toList();
    if (posts.isEmpty) return posts;

    final paths = posts.map((p) => p.photoUrl).toList();
    final signed = await _client.storage
        .from(_postsBucket)
        .createSignedUrls(paths, _signedUrlExpiry);

    return [
      for (var i = 0; i < posts.length; i++)
        posts[i].copyWith(photoUrl: signed[i].signedUrl),
    ];
  }

  /// 특정 week에 해당하는 포스트 목록 (created_at 오름차순)
  ///
  /// photo_url에 저장된 스토리지 경로를 signed URL로 변환하여 반환한다.
  /// 그룹 멤버만 signed URL을 생성할 수 있으므로 비멤버는 이미지에 접근 불가.
  Future<List<Post>> getPostsByWeek(Group group, int weekIndex) async {
    final rows = await _client
        .from('posts')
        .select('id, group_id, author_id, week_index, photo_url, caption, created_at')
        .eq('group_id', group.id)
        .eq('week_index', weekIndex)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    final posts = (rows as List).map((r) => Post.fromJson(r)).toList();
    if (posts.isEmpty) return posts;

    final paths = posts.map((p) => p.photoUrl).toList();
    final signed = await _client.storage
        .from(_postsBucket)
        .createSignedUrls(paths, _signedUrlExpiry);

    return [
      for (var i = 0; i < posts.length; i++)
        posts[i].copyWith(
          photoUrl: signed[i].signedUrl,
        ),
    ];
  }

  /// 그룹의 주별 포스트 요약 (각 주의 최신 포스트 1개 + 총 개수)
  ///
  /// 반환: weekIndex 내림차순 (최신 주 먼저)
  Future<List<({int weekIndex, int postCount, List<String> authorIds, Post? latestPost})>>
      getWeekPostSummaries(Group group) async {
    final rows = await _client
        .from('posts')
        .select('id, group_id, author_id, week_index, photo_url, caption, created_at')
        .eq('group_id', group.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    final allPosts = (rows as List).map((r) => Post.fromJson(r)).toList();
    if (allPosts.isEmpty) return [];

    final byWeek = <int, List<Post>>{};
    for (final p in allPosts) {
      byWeek.putIfAbsent(p.weekIndex, () => []).add(p);
    }

    final pathsToSign = <String>[];
    final weekEntries = byWeek.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    for (final e in weekEntries) {
      pathsToSign.add(e.value.last.photoUrl);
    }

    final signed = pathsToSign.isNotEmpty
        ? await _client.storage
              .from(_postsBucket)
              .createSignedUrls(pathsToSign, _signedUrlExpiry)
        : <SignedUrl>[];

    return [
      for (var i = 0; i < weekEntries.length; i++)
        (
          weekIndex: weekEntries[i].key,
          postCount: weekEntries[i].value.length,
          authorIds: weekEntries[i]
              .value
              .map((p) => p.authorId)
              .toSet()
              .toList(),
          latestPost: weekEntries[i].value.last.copyWith(
            photoUrl: signed[i].signedUrl,
          ),
        ),
    ];
  }

  /// 포스트 좋아요 수
  Future<int> getPostLikeCount(String postId) async {
    final res = await _client
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .count(CountOption.exact);
    return res.count;
  }

  /// 포스트에 좋아요한 유저 ID 목록
  Future<List<String>> getPostLikedUserIds(String postId) async {
    final rows = await _client
        .from('post_likes')
        .select('user_id')
        .eq('post_id', postId)
        .order('created_at');
    return (rows as List).map((r) => r['user_id'] as String).toList();
  }

  /// 포스트 댓글 수
  Future<int> getPostCommentCount(String postId) async {
    final res = await _client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);
    return res.count;
  }

  /// 현재 유저가 해당 포스트에 좋아요했는지 확인
  Future<bool> isPostLikedByCurrentUser(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final rows = await _client
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  /// 좋아요 토글 (좋아요 안 했으면 추가, 했으면 삭제)
  ///
  /// [currentlyLiked]를 전달하면 DB 조회 없이 바로 insert/delete 실행.
  /// 반환: 토글 후 좋아요 상태 (true=좋아요됨)
  Future<bool> toggleLike(String postId, {bool? currentlyLiked}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final liked = currentlyLiked ?? await isPostLikedByCurrentUser(postId);
    if (liked) {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return false;
    } else {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      return true;
    }
  }

  /// 포스트 삭제
  Future<void> deletePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');
    await _client.from('posts').delete().eq('id', postId).eq('author_id', userId);
  }
}
