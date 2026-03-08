import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/home/widgets/post_card.dart';
import 'package:bemyday/features/home/widgets/post_count_badge.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostStack extends ConsumerWidget {
  const PostStack({super.key, required this.group});

  final Group group;

  static const int _maxVisible = 4;

  void _onPostTap(BuildContext context) {
    context.push(PostScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(currentWeekPostsProvider(group));
    final dark = isDarkMode(context);
    final borderColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final bgColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final beforeReveal = isCurrentWeekBeforeReveal(group);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();

        final totalCount = posts.length;
        final reversed = posts.reversed.toList();
        final visible = reversed.take(_maxVisible).toList();
        final cardCount = visible.length;

        return GestureDetector(
          onTap: () => _onPostTap(context),
          child: FractionallySizedBox(
            heightFactor: 0.95,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight;
                final cardWidth = cardHeight * ARatio.common;
                const spacing = 16.0;
                const angles = [-0.04, 0.0, 0.04, 0.08];
                final totalWidth = cardWidth + (cardCount - 1) * spacing;
                final startX = (constraints.maxWidth - totalWidth) / 2;

                final lastCardRight =
                    startX + (cardCount - 1) * spacing + cardWidth;
                final cardBottom =
                    (constraints.maxHeight - cardHeight) / 2 + cardHeight;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = cardCount - 1; i >= 0; i--)
                      Positioned(
                        left: startX + i * spacing,
                        top: (constraints.maxHeight - cardHeight) / 2,
                        width: cardWidth,
                        height: cardHeight,
                        child: Transform.rotate(
                          angle: angles[i],
                          alignment: Alignment.center,
                          child: PostCard(
                            post: visible[i],
                            borderColor: borderColor,
                            bgColor: bgColor,
                            blur: beforeReveal &&
                                visible[i].authorId != currentUserId,
                          ),
                        ),
                      ),
                    if (totalCount >= 5)
                      Positioned(
                        left: lastCardRight - Sizes.size64,
                        top: cardBottom - Sizes.size28,
                        child: PostCountBadge(count: totalCount),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
