import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/comments/models/comment.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 댓글이 있는 게시글의 넛지 배너 - 최신 댓글 미리보기
class CommentNudgeBanner extends ConsumerWidget {
  const CommentNudgeBanner({
    super.key,
    required this.comment,
    required this.onTap,
  });

  final Comment comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(comment.authorId));
    final nickname = profileAsync.valueOrNull?.nickname ?? '?';
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.scaffoldH,
          vertical: Paddings.scaffoldV,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RValues.button),
          child: BackdropFilter(
            filter: Blurs.backdrop,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Paddings.buttonH,
                vertical: Paddings.buttonV,
              ),
              decoration: BoxDecoration(
                color: Blurs.overlayColor,
                borderRadius: BorderRadius.circular(RValues.button),
                border: Border.all(color: CustomColors.borderDark),
              ),
              child: Row(
                children: [
                  AvatarDefault(
                    nickname: nickname,
                    avatarUrl: avatarUrl,
                    radius: Sizes.size16,
                  ),
                  CustomSizes.commentLeadingGap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            comment.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Sizes.size12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),

                        Text(
                          formatTimeAgo(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: CustomColors.hintColorDark,
                                fontSize: Sizes.size10,
                              ),
                        ),
                      ],
                    ),
                  ),
                  CustomSizes.commentTrailingGap,
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: CustomSizes.tileTrailingIcon,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
