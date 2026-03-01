import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/providers/invitation_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  bool _isDeclining = false;

  void _onCloseTap(BuildContext context) {
    context.pop();
  }

  Future<void> _onAcceptTap(BuildContext context) async {
    if (_isAccepting || _isDeclining) return;
    setState(() => _isAccepting = true);
    try {
      await ref.read(invitationRepositoryProvider).acceptInvitation(widget.inviteToken);
      ref.invalidate(currentUserGroupsProvider);
      if (context.mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _onDeclineTap(BuildContext context) {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(invitationRepositoryProvider).getInvitationByToken(widget.inviteToken),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final isError = snapshot.hasError || (snapshot.hasData && data == null);

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
              actions: [
                GestureDetector(
                  onTap: () => _onCloseTap(context),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.circleXmark, size: Sizes.size20),
                  ),
                ),
              ],
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                    ? Center(
                        child: Text(
                          '유효하지 않거나 만료된 초대입니다',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarDefault(
                              avatarUrl: data?['inviter_avatar_url'] as String?,
                              nickname: data?['inviter_nickname'] as String? ?? '?',
                              radius: 32,
                            ),
                            Gaps.v16,
                            Text(
                              '${data?['inviter_nickname'] ?? '?'}님이 초대했어요',
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
            bottomNavigationBar: !isLoading && !isError
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Paddings.scaffoldH,
                        vertical: Paddings.scaffoldV,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isAccepting
                                  ? null
                                  : () => _onDeclineTap(context),
                              child: const Text("Decline"),
                            ),
                          ),
                          Gaps.h16,
                          Expanded(
                            child: FilledButton(
                              onPressed: _isDeclining
                                  ? null
                                  : () => _onAcceptTap(context),
                              child: _isAccepting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Accept"),
                            ),
                          ),
                        ],
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
