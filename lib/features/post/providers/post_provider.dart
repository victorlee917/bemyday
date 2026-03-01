import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/post/repositories/post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

/// 현재 week에 해당하는 포스트 존재 여부
final hasCurrentWeekPostsProvider =
    FutureProvider.family<bool, Group>((ref, group) async {
  return ref.read(postRepositoryProvider).hasCurrentWeekPosts(group);
});
