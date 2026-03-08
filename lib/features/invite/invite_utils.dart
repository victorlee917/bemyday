import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// InviteScreen을 모달 시트로 표시
/// 요일을 먼저 결정한 뒤 시트를 열어 UI 깜빡임 방지
Future<void> showInviteSheet(
  BuildContext context,
  WidgetRef ref, {
  int? selectedWeekdayIndex,
}) async {
  final resolvedIndex = await ref.read(
    effectiveInviteWeekdayIndexProvider(selectedWeekdayIndex).future,
  );
  if (!context.mounted) return;

  final screenHeight = MediaQuery.of(context).size.height;
  final safeAreaTop = MediaQuery.of(context).padding.top;
  final availableHeight = screenHeight - safeAreaTop;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(RValues.bottomsheet),
      ),
    ),
    builder: (context) => SizedBox(
      height: availableHeight * 0.8,
      child: InviteScreen(selectedWeekdayIndex: resolvedIndex),
    ),
  );
}

/// 그룹이 없으면 InviteScreen으로 이동
///
/// [popCount]: 이동 전 pop할 횟수 (PostingDecorate는 2)
void redirectToInviteIfNoGroups(
  BuildContext context,
  WidgetRef ref, {
  int popCount = 0,
}) {
  final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
  if (groups.isEmpty && context.mounted) {
    for (var i = 0; i < popCount; i++) {
      Navigator.of(context).pop();
    }
    if (context.mounted) {
      context.go(InviteScreen.routeUrl);
    }
  }
}
