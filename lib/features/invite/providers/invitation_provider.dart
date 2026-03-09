import 'package:bemyday/features/invite/repositories/invitation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});

/// 토큰으로 초대 정보 조회 (캐시되어 재빌드 시에도 안정적)
final invitationByTokenProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, token) async {
  return ref.read(invitationRepositoryProvider).getInvitationByToken(token);
});
