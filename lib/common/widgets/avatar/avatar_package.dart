import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class AvatarPackage extends StatelessWidget {
  const AvatarPackage({
    super.key,
    required this.nickname,
    required this.title,
    this.avatarUrl,
    this.avatarWidget,
    this.childTitle,
    this.subTitle,
    this.isDarkOnly = false,
  });

  final String nickname;
  final String title;
  final String? avatarUrl;
  final Widget? avatarWidget;
  final String? childTitle;
  final String? subTitle;
  final bool isDarkOnly;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTitleWidth = constraints.maxWidth * 0.6;
          return Row(
            children: [
              avatarWidget ??
                  AvatarDefault(
                    nickname: nickname,
                    avatarUrl: avatarUrl,
                    radius: CustomSizes.avatarComment,
                  ),
              CustomSizes.commentLeadingGap,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: childTitle != null && childTitle!.isNotEmpty
                            ? null
                            : maxTitleWidth,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDarkMode(context) || isDarkOnly
                                ? Colors.white
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      if (childTitle != null && childTitle!.isNotEmpty) ...[
                        CustomSizes.commentDateGap,
                        Opacity(
                          opacity: 0.3,
                          child: Text(
                            childTitle!,
                            style: TextStyle(
                              fontSize: Sizes.size12,
                              color: isDarkMode(context) || isDarkOnly
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subTitle != null && subTitle!.isNotEmpty)
                    Opacity(
                      opacity: 0.5,
                      child: Text(
                        subTitle!,
                        style: TextStyle(
                          fontSize: Sizes.size12,
                          color: isDarkMode(context) || isDarkOnly
                              ? Colors.white
                              : Colors.black,
                        ),
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
