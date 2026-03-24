import 'dart:io';

import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ViewModel] 포스트 생성
///
/// - Repository를 통해 Supabase에 포스트 업로드
/// - 성공 시 currentUserGroupsProvider invalidate
/// - 실패 시 예외 발생 (Screen에서 스낵바 처리)
class PostingViewModel {
  PostingViewModel(this.ref);
  final Ref ref;

  /// 포스트 생성
  ///
  /// 성공 시 반환. 실패 시 예외 발생.
  Future<String> createPost(Group group, File file) async {
    final id = await ref.read(postRepositoryProvider).createPost(group, file);
    ref.invalidate(currentUserGroupsProvider);
    return id;
  }
}

final postingViewModelProvider = Provider<PostingViewModel>((ref) {
  return PostingViewModel(ref);
});
