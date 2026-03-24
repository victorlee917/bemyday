import 'package:bemyday/common/widgets/avatar/horizontal_avatar_stack.dart';
import 'package:bemyday/common/widgets/blur_overlay_card.dart';
import 'package:bemyday/common/widgets/stat/stats_collection.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/home/widgets/post_empty.dart';
import 'package:bemyday/features/home/widgets/post_stack.dart';
import 'package:bemyday/features/invite/widgets/invite_card.dart'
    show inviteCardDimensions;
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/features/post/providers/post_provider.dart'
    show groupLatestRevealedPostsProvider;
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Friends 화면용. PostStack + blur 오버레이로 그룹 표현.
/// TutorialPostStackWithBlur와 동일한 레이아웃.
class GroupPostStackWithBlur extends ConsumerWidget {
  const GroupPostStackWithBlur({
    super.key,
    required this.group,
    required this.weekdayIndex,
  });

  final Group group;
  final int weekdayIndex;

  void _onTap(BuildContext context) {
    context.push(PartyScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (_, postStackCardHeight) = inviteCardDimensions(context);

    return ref
        .watch(groupLatestRevealedPostsProvider(group))
        .when(
          data: (posts) {
            return _GroupPostStackWithBlurContent(
              group: group,
              weekdayIndex: weekdayIndex,
              hasPosts: posts.isNotEmpty,
              postStackCardHeight: postStackCardHeight,
              onTap: () => _onTap(context),
            );
          },
          loading: () => _GroupPostStackWithBlurContent(
            group: group,
            weekdayIndex: weekdayIndex,
            hasPosts: false,
            postStackCardHeight: postStackCardHeight,
            onTap: () => _onTap(context),
          ),
          error: (_, __) => _GroupPostStackWithBlurContent(
            group: group,
            weekdayIndex: weekdayIndex,
            hasPosts: false,
            postStackCardHeight: postStackCardHeight,
            onTap: () => _onTap(context),
          ),
        );
  }
}

class _GroupPostStackWithBlurContent extends ConsumerWidget {
  const _GroupPostStackWithBlurContent({
    required this.group,
    required this.weekdayIndex,
    required this.hasPosts,
    required this.postStackCardHeight,
    required this.onTap,
  });

  final Group group;
  final int weekdayIndex;
  final bool hasPosts;
  final double postStackCardHeight;
  final VoidCallback onTap;

  static const _scaleFactor = 0.9;
  static const _postStackSpacing = 16.0;
  static const _postStackCardCount = 4;
  static const _blurWidthFactor = 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final blurHeightFactor = screenWidth < 330 ? 1.4 : 1.5;
    final stackHeight = postStackCardHeight * _scaleFactor;
    final blurContainerHeight = stackHeight / blurHeightFactor;
    final dark = isDarkMode(context);

    final cardWidth = postStackCardHeight * ARatio.common;
    final postStackTotalWidth =
        cardWidth + (_postStackCardCount - 1) * _postStackSpacing;
    final postStackScaledWidth = postStackTotalWidth * _scaleFactor;
    final availableWidth = screenWidth - Paddings.scaffoldH * 2;
    final blurContainerWidth = (postStackScaledWidth * _blurWidthFactor).clamp(
      0.0,
      availableWidth * 0.85,
    );

    final displayName =
        ref.watch(groupDisplayNameProvider(group.id)).valueOrNull ?? '…';
    final weeks = groupWeekNumber(group);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
        child: SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: _scaleFactor,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: postStackCardHeight,
                  child: hasPosts
                      ? PostStack(
                          group: group,
                          useLatestPosts: true,
                          useRevealedPostsOnly: true,
                          onTap: onTap,
                        )
                      : PostEmpty(
                          weekdayIndex: weekdayIndex,
                          compactForBlur: true,
                        ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // height: blurContainerHeight,
                child: Center(
                  child: RepaintBoundary(
                    child: BlurOverlayCard(
                      width: blurContainerWidth,
                      height: blurContainerHeight,
                      dark: dark,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdays[weekdayIndex].name,
                            style: GoogleFonts.darumadropOne(
                              fontSize: Sizes.size20,
                            ),
                          ),
                          Gaps.v16,
                          _GroupAvatarStack(groupId: group.id, dark: dark),
                          Gaps.v8,
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: Sizes.size14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Gaps.v12,
                          StatsCollection(
                            stats: [
                              StatItem(title: l10n.statWeeks, value: weeks),
                              StatItem(
                                title: l10n.statStreaks,
                                value: group.streak,
                              ),
                              StatItem(
                                title: l10n.statPosts,
                                value: group.postCount,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAvatarStack extends ConsumerWidget {
  const _GroupAvatarStack({required this.groupId, required this.dark});

  final String groupId;
  final bool dark;

  static const _avatarSize = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarsAsync = ref.watch(groupMemberAvatarsProvider(groupId));

    return avatarsAsync.when(
      data: (avatars) {
        final others = avatars.length > 1
            ? avatars.sublist(0, avatars.length - 1)
            : avatars;
        if (others.isEmpty) {
          return SizedBox(
            height: _avatarSize,
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: Sizes.size14,
                  color: dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          );
        }
        return HorizontalAvatarStack(members: others, dark: dark);
      },
      loading: () => SizedBox(
        height: _avatarSize,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: _avatarSize,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: Sizes.size14,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
