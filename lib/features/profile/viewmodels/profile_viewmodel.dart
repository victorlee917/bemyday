import 'package:bemyday/features/profile/providers/profile_repository_provider.dart';
import 'package:bemyday/features/profile/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ViewModel] 프로필 닉네임 저장
///
/// - Repository를 통해 Supabase에 닉네임 업데이트
/// - 저장 성공/실패는 Screen에서 처리 (네비게이션, 스낵바)
class ProfileViewModel {
  ProfileViewModel(this.ref);
  final Ref ref;

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  /// 닉네임 저장/수정
  ///
  /// - 성공 시 반환
  /// - 실패 시 예외 발생 (PostgrestException 등)
  Future<void> saveNickname(String nickname) async {
    await _repository.updateNickname(nickname);
  }
}

/// ViewModel Provider
final profileViewModelProvider = Provider<ProfileViewModel>((ref) {
  return ProfileViewModel(ref);
});
