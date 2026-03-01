import 'package:bemyday/features/profile/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile Repository Provider
///
/// profile_provider, profile_viewmodel 등에서 공통 사용.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
