import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/features/profile/providers/profile_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 로그인 유저 프로필 (닉네임, 프로필 사진)
///
/// 여러 화면에서 공통 사용. ref.invalidate(currentProfileProvider)로 새로고침
/// autoDispose 제거: 화면 재진입 시마다 재요청되는 것 방지
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  return ref.read(profileRepositoryProvider).getProfile();
});

/// 특정 유저 프로필 조회
///
/// ref.watch(profileProvider(userId)) 형태로 사용
final profileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  return ref.read(profileRepositoryProvider).getProfile(userId: userId);
});
