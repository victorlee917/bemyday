import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/providers/invitation_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 초대 받은 사람이 딥링크(https://bemyday.app/invite/:token)로 진입하는 화면
///
/// Accept / Decline
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key, required this.inviteToken});
  static const routeName = "invitation";

  /// 딥링크 경로에서 전달된 토큰
  final String inviteToken;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  bool _isAccepting = false;

  void _onCloseTap(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _onAcceptTap(BuildContext context) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    try {
      await ref.read(invitationRepositoryProvider).acceptInvitation(widget.inviteToken);
      ref.invalidate(currentUserGroupsProvider);
      if (context.mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '참여에 실패했습니다: $e');
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(invitationRepositoryProvider).getInvitationByToken(widget.inviteToken),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final isError = snapshot.hasError || (snapshot.hasData && data == null);
        final invitationGroupId = data?['group_id'] as String?;
        final userGroups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];
        final isAlreadyMember = invitationGroupId != null &&
            userGroups.any((g) => g.id == invitationGroupId);
        // inviter_nickname (snake_case) 또는 inviterNickname (camelCase) 지원
        final inviterNickname = (data?['inviter_nickname'] ?? data?['inviterNickname']) as String?;
        final displayName = (inviterNickname ?? '').trim().isNotEmpty ? inviterNickname!.trim() : '초대자';

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(RValues.bottomsheet),
              topRight: Radius.circular(RValues.bottomsheet),
            ),
          ),
          child: Scaffold(
            backgroundColor: isDarkMode(context)
                ? CustomColors.sheetColorDark
                : CustomColors.sheetColorLight,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text("Invitation"),
              backgroundColor: isDarkMode(context)
                  ? CustomColors.sheetColorDark
                  : CustomColors.sheetColorLight,
              actions: [CloseAppBarButton(onTap: () => _onCloseTap(context))],
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                          child: Text(
                            '유효하지 않거나 만료된 초대입니다',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : isAlreadyMember
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                                  child: Text(
                                    '이미 가입된 그룹입니다',
                                    style: Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Padding(
                            padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AvatarDefault(
                                  avatarUrl: (data?['inviter_avatar_url'] ?? data?['inviterAvatarUrl']) as String?,
                                  nickname: displayName,
                                  radius: 32,
                                ),
                                Gaps.v16,
                                Text(
                                  '$displayName님이 초대했어요',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                Gaps.v8,
                                Text(
                                  'Would You Be My ${weekdays[((data?['weekday'] as int?) ?? 1) - 1].name}?',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
            bottomNavigationBar: !isLoading && !isError && !isAlreadyMember
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Paddings.scaffoldH,
                        vertical: Paddings.scaffoldV,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isAccepting ? null : () => _onAcceptTap(context),
                          child: _isAccepting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Accept"),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
