import 'package:bemyday/features/invite/repositories/invitation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});
