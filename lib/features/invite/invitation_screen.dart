import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/providers/invitation_provider.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 초대 받은 사람이 딥링크(https://bemyday.app/invitation/:token)로 진입하는 화면
///
/// Accept / Decline
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key, required this.inviteToken});
  static const routeName = "invitation";
  static const routeUrl = "/invitation";

  /// 딥링크 경로에서 전달된 토큰
  final String inviteToken;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  bool _isAccepting = false;

  DateTime? _parseExpiresAt(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<Color>? _parseGradientColors(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    final colors = <Color>[];
    for (final item in value) {
      if (item is! String) continue;
      final hex = item.trim();
      if (hex.isEmpty || !hex.startsWith('#')) continue;
      final parsed = _hexToColor(hex);
      if (parsed != null) colors.add(parsed);
    }
    return colors.length >= 3 ? colors : null;
  }

  Color? _hexToColor(String hex) {
    if (hex.length != 7 || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value != null ? Color(0xFF000000 | value) : null;
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
    final invitationAsync = ref.watch(invitationByTokenProvider(widget.inviteToken));
    final userGroups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];

    return invitationAsync.when(
      loading: () => _buildScaffold(
        context,
        isLoading: true,
        isError: false,
        data: null,
        userGroups: userGroups,
      ),
      error: (_, __) => _buildScaffold(
        context,
        isLoading: false,
        isError: true,
        data: null,
        userGroups: userGroups,
      ),
      data: (data) => _buildScaffold(
        context,
        isLoading: false,
        isError: data == null,
        data: data,
        userGroups: userGroups,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isLoading,
    required bool isError,
    required Map<String, dynamic>? data,
    required List<dynamic> userGroups,
  }) {
    final invitationGroupId = data?['group_id'] as String?;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isInviter = currentUserId != null &&
        (data?['inviter_id'] ?? data?['inviterId']) == currentUserId;
    final isAlreadyMember = isInviter ||
        (invitationGroupId != null &&
            userGroups.any((g) => g.id == invitationGroupId));
    // inviter_nickname (snake_case) 또는 inviterNickname (camelCase) 지원
    final inviterNickname = (data?['inviter_nickname'] ?? data?['inviterNickname']) as String?;
    final displayName = (inviterNickname ?? '').trim().isNotEmpty ? inviterNickname!.trim() : '초대자';
    final rawAvatar = data?['inviter_avatar_url'] ?? data?['inviterAvatarUrl'];
    final inviterAvatarUrl = (rawAvatar is String && rawAvatar.trim().isNotEmpty)
        ? rawAvatar.trim()
        : null;
    final gradientColors = _parseGradientColors(data?['gradient_colors'] ?? data?['gradientColors']);
    final expiresAt = _parseExpiresAt(data?['expires_at'] ?? data?['expiresAt']);
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

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
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                          child: Text(
                            'Expired Invitation',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final width = (screenWidth - Paddings.scaffoldH * 2) * 0.9;
                            final height = width * (3 / 2);
                            final parsedExpiresAt = isAlreadyMember
                                ? null
                                : _parseExpiresAt(data?['expires_at'] ?? data?['expiresAt']);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(RValues.island),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Tilt(
                                    tiltConfig: TiltConfig(
                                      enableGestureTouch: true,
                                      enableGestureHover: true,
                                      enableGestureSensors: true,
                                      angle: 4,
                                      sensorFactor: 8,
                                      enableReverse: true,
                                    ),
                                    lightConfig: LightConfig(disable: true),
                                    shadowConfig: ShadowConfig(disable: true),
                                    borderRadius: BorderRadius.circular(RValues.island),
                                    child: InviteCard(
                                      weekdayName: weekdays[((data?['weekday'] as int?) ?? 1) - 1].name,
                                      inviterNickname: displayName,
                                      inviterAvatarUrl: inviterAvatarUrl,
                                      gradientColors: gradientColors,
                                      width: width,
                                      height: height,
                                    ),
                                  ),
                                ),
                                if (parsedExpiresAt != null) ...[
                                  Gaps.v16,
                                  InviteExpiryCountdown(expiresAt: parsedExpiresAt),
                                ],
                                if (isAlreadyMember) ...[
                                  Gaps.v16,
                                  ChipContainer(
                                    child: Text(
                                      'Already a member',
                                      style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: Sizes.size10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
            bottomNavigationBar: isLoading
                ? null
                : isError
                    ? SafeArea(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: Paddings.scaffoldH,
                            right: Paddings.scaffoldH,
                            bottom: Paddings.scaffoldV,
                          ),
                          child: GestureDetector(
                            onTap: () => context.go('/home'),
                            child: Container(
                              width: double.infinity,
                              height: Sizes.size48,
                              decoration: BoxDecoration(
                                color: isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(RValues.button),
                              ),
                              child: Center(
                                child: Text(
                                  'Ok',
                                  style: Theme.of(context).textTheme.labelLarge!
                                      .copyWith(
                                        color: isDarkMode(context)
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : (!isAlreadyMember ? !isExpired : true)
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: Paddings.scaffoldH,
                        right: Paddings.scaffoldH,
                        bottom: Paddings.scaffoldV,
                      ),
                      child: GestureDetector(
                        onTap: _isAccepting && !isAlreadyMember
                            ? null
                            : () => isAlreadyMember
                                ? context.go('/home')
                                : _onAcceptTap(context),
                        child: Opacity(
                          opacity: _isAccepting && !isAlreadyMember ? 0.7 : 1.0,
                          child: Container(
                            width: double.infinity,
                            height: Sizes.size48,
                            decoration: BoxDecoration(
                              color: isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                              borderRadius: BorderRadius.circular(RValues.button),
                            ),
                            child: Center(
                              child: _isAccepting && !isAlreadyMember
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDarkMode(context)
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isAlreadyMember ? "Ok" : "Accept",
                                      style: Theme.of(context).textTheme.labelLarge!
                                          .copyWith(
                                            color: isDarkMode(context)
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
  }
}
