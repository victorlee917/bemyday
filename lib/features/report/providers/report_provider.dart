import 'package:bemyday/features/report/repositories/block_repository.dart';
import 'package:bemyday/features/report/repositories/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});

/// 차단된 사용자 ID 목록 (캐시)
final blockedUserIdsProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(blockRepositoryProvider).getBlockedUserIds();
});
