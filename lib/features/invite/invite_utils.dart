import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invitation_screen.dart';
import 'package:bemyday/features/invite/invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// InviteScreen·InvitationScreen 공통 시트 높이 비율
double _inviteSheetHeightFactor(double availableHeight) {
  return availableHeight < 680 ? 0.85 : 0.75;
}

/// InvitationScreen을 모달 시트로 표시 (InviteScreen과 동일한 높이)
Future<void> showInvitationSheet(
  BuildContext context,
  WidgetRef ref, {
  required String inviteToken,
}) async {
  final screenHeight = MediaQuery.of(context).size.height;
  final safeAreaTop = MediaQuery.of(context).padding.top;
  final availableHeight = screenHeight - safeAreaTop;
  final heightFactor = _inviteSheetHeightFactor(availableHeight);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(RValues.bottomsheet),
      ),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: heightFactor,
      minChildSize: heightFactor,
      maxChildSize: heightFactor,
      expand: false,
      builder: (context, _) =>
          InvitationScreen(inviteToken: inviteToken, asSheet: true),
    ),
  );
}

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
  final heightFactor = _inviteSheetHeightFactor(availableHeight);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(RValues.bottomsheet),
      ),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: heightFactor,
      minChildSize: heightFactor,
      maxChildSize: heightFactor,
      expand: false,
      builder: (context, _) =>
          InviteScreen(selectedWeekdayIndex: resolvedIndex),
    ),
  );
}

/// 그룹이 없으면 InviteScreen 바텀시트 표시
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
      showInviteSheet(context, ref);
    }
  }
}
