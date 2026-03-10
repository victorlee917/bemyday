import 'dart:ui';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:bemyday/common/widgets/cached_post_image.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeekGridItem {
  const WeekGridItem({
    required this.weekIndex,
    required this.postCount,
    this.authorIds = const [],
    this.latestPost,
    this.isCurrentWeek = false,
  });

  final int weekIndex;
  final int postCount;
  final List<String> authorIds;
  final Post? latestPost;
  final bool isCurrentWeek;
}

class WeekGridCard extends ConsumerWidget {
  const WeekGridCard({super.key, required this.item, required this.group});

  final WeekGridItem item;
  final Group group;

  void _onAddPostTap(BuildContext context) async {
    final weekdayIndex = group.weekday - 1;
    final result = await context.push(
      PostingAlbumScreen.routeUrl,
      extra: weekdayIndex,
    );
    if (result is Group && context.mounted) {
      context.push(
        PostScreen.routeUrl,
        extra: {'group': result, 'startFromLatest': true},
      );
    }
  }

  void _onPostTap(BuildContext context) {
    context.push(
      PostScreen.routeUrl,
      extra: {
        'group': group,
        'weekIndex': item.weekIndex,
        'startFromLatest': false,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPost = item.latestPost != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Week ${item.weekIndex}",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (hasPost) _buildAuthorAvatars(context, ref),
          ],
        ),
        Gaps.v8,
        Expanded(
          child: hasPost ? _buildPostCard(context) : _buildEmptyCard(context),
        ),
      ],
    );
  }

  Widget _buildAuthorAvatars(BuildContext context, WidgetRef ref) {
    const double avatarSize = 20;

    final ids = item.authorIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    final settings = RestrictedPositions(
      maxCoverage: 0.5,
      minCoverage: 0.4,
      align: StackAlign.right,
    );

    final avatarWidgets = ids.map((id) {
      final profile = ref.watch(profileProvider(id)).valueOrNull;
      final url = profile?.avatarUrl;
      return Container(
        decoration: ShapeDecoration(
          shape: CircleBorder(
            side: BorderSide(
              color: isDarkMode(context)
                  ? CustomColors.borderDark
                  : CustomColors.borderLight,
              width: 2,
            ),
          ),
        ),
        child: ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                  )
                : ColoredBox(
                    color: isDarkMode(context)
                        ? CustomColors.primaryColorDark
                        : CustomColors.primaryColorLight,
                    child: Center(
                      child: Text(
                        profile?.nickname.characters.first ?? '?',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }).toList();

    return SizedBox(
      height: avatarSize,
      width: avatarSize * ids.length.clamp(1, 4).toDouble(),
      child: WidgetStack(
        positions: settings,
        stackedWidgets: avatarWidgets,
        buildInfoWidget: (surplus, _) => Container(
          width: avatarSize,
          height: avatarSize,
          decoration: ShapeDecoration(
            color: Colors.grey.shade300,
            shape: CircleBorder(
              side: BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
          child: Center(
            child: Text(
              '+$surplus',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark
        ? CustomColors.clickableAreaDark
        : CustomColors.clickableAreaLight;
    final post = item.latestPost!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final shouldBlur =
        item.isCurrentWeek &&
        isCurrentWeekBeforeReveal(group) &&
        post.authorId != currentUserId;

    return GestureDetector(
      onTap: () => _onPostTap(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RValues.thumbnail),
          border: Border.all(
            color: dark ? CustomColors.borderDark : CustomColors.borderLight,
            width: Widths.devider,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RValues.thumbnail),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: shouldBlur
                    ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: CachedPostImage(
                  imageUrl: post.photoUrl,
                  cacheKey: post.storagePath,
                  placeholderColor: bgColor,
                  errorWidget: Container(
                    color: bgColor,
                    child: const Center(child: FaIcon(FontAwesomeIcons.image)),
                  ),
                ),
              ),
              if (item.postCount > 1)
                Positioned(
                  right: Sizes.size12,
                  bottom: Sizes.size12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RValues.thumbnail),
                    child: BackdropFilter(
                      filter: Blurs.backdrop,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Sizes.size8,
                          vertical: Sizes.size3,
                        ),
                        decoration: BoxDecoration(
                          color: Blurs.overlayColor,
                          borderRadius: BorderRadius.circular(
                            RValues.thumbnail,
                          ),
                          border: Border.all(color: CustomColors.borderDark),
                        ),
                        child: Text(
                          "${item.postCount} Posts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Sizes.size11,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildEmptyCard(BuildContext context) {
    final dark = isDarkMode(context);
    return GestureDetector(
      onTap: () => _onAddPostTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: dark
              ? CustomColors.clickableAreaDark
              : CustomColors.clickableAreaLight,
          border: Border.all(
            color: dark ? CustomColors.borderDark : CustomColors.borderLight,
            width: Sizes.size1,
          ),
          borderRadius: BorderRadius.circular(RValues.thumbnail),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.circlePlus),
              Gaps.v12,
              Text(
                "No posts yet",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v6,
              Opacity(
                opacity: 0.5,
                child: Text(
                  "Add posts",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
