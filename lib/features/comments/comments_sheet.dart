import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.scrollController,
    required this.autofocus,
  });

  final bool autofocus;

  final ScrollController scrollController;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  String _comment = "";

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged(String value) {
    setState(() {
      _comment = value;
    });
  }

  void _onClosePressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            ? CustomColors.backgroundColorDark
            : CustomColors.backgroundColorLight,
        body: Stack(
          children: [
            CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: isDarkMode(context)
                      ? CustomColors.backgroundColorDark
                      : CustomColors.backgroundColorLight,
                  shape: Border(
                    bottom: BorderSide(
                      color: isDarkMode(context)
                          ? CustomColors.borderDark
                          : CustomColors.borderLight,
                      width: Widths.devider,
                    ),
                  ),
                  title: Text("Comments"),
                  actions: [
                    GestureDetector(
                      onTap: _onClosePressed,
                      child: FaIcon(
                        FontAwesomeIcons.circleXmark,
                        size: Sizes.size20,
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: Paddings.scaffoldH,
                    right: Paddings.scaffoldH,
                    top: Paddings.scaffoldV,
                    bottom:
                        kToolbarHeight +
                        MediaQuery.of(context).padding.bottom +
                        Paddings.scaffoldV * 2 +
                        Sizes.size10,
                  ),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Sizes.size16,
                        vertical: Sizes.size16,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode(context)
                            ? CustomColors.nonClickableAreaDark
                            : CustomColors.nonClickableAreaLight,
                        borderRadius: BorderRadius.circular(Sizes.size24),
                      ),
                      child: Row(
                        children: [
                          AvatarDefault(
                            nickname: "Bogus",
                            radius: CustomSizes.avatarComment,
                          ),
                          CustomSizes.commentLeadingGap,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Bogus",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    CustomSizes.commentDateGap,
                                    Opacity(
                                      opacity: 0.3,
                                      child: Text(
                                        "1hour before",
                                        style: TextStyle(
                                          fontSize: Sizes.size10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "commentsssss",
                                  style: TextStyle(fontSize: Sizes.size12),
                                ),
                              ],
                            ),
                          ),
                          FaIcon(FontAwesomeIcons.heart, size: Sizes.size20),
                        ],
                      ),
                    ),
                    separatorBuilder: (context, index) => Gaps.v16,
                    itemCount: 20,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode(context)
                          ? CustomColors.borderDark
                          : CustomColors.borderLight,
                      width: Widths.devider,
                    ),
                  ),
                ),
                child: BottomAppBar(
                  padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                  color: isDarkMode(context)
                      ? CustomColors.backgroundColorDark
                      : CustomColors.backgroundColorLight,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          onChanged: _onCommentChanged,
                          style: TextStyle(fontSize: Sizes.size14),
                          cursorHeight: Sizes.size14,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: AvatarDefault(
                                nickname: "Bogus",
                                radius: Sizes.size16,
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            suffixIcon: _comment.isNotEmpty
                                ? Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: FaIcon(
                                      FontAwesomeIcons.circleArrowUp,
                                      size: Sizes.size20,
                                    ),
                                  )
                                : null,
                            suffixIconConstraints: BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            hintText: "Leave a comment...",
                            hintStyle: TextStyle(
                              color: isDarkMode(context)
                                  ? CustomColors.hintColorDark
                                  : CustomColors.hintColorLight,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Paddings.buttonH,
                              vertical: Paddings.buttonV,
                            ),
                            filled: true,
                            fillColor: isDarkMode(context)
                                ? CustomColors.clickableAreaDark
                                : CustomColors.clickableAreaLight,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(
                                RValues.button,
                              ),
                            ),
                          ),
                          autocorrect: false,
                          autofocus: widget.autofocus,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
