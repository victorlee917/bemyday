import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/comments/comments_sheet.dart';
import 'package:bemyday/features/post/widgets/index_indicator.dart';
import 'package:bemyday/features/post/widgets/post_bottom_bar.dart';
import 'package:bemyday/features/post/widgets/post_comment_bubble.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class BubbleTailPainter extends CustomPainter {
  final Color color;

  BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 오른쪽을 향하는 곡선 말풍선 꼭지
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.3,
        size.width,
        size.height / 2,
      )
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.7, 0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});
  static const routeName = "post";
  static const routeUrl = "/post";

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  int _currentIndex = 0;
  final int _itemCount = 5;

  void _onTapUp(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth / 2) {
      // 왼쪽 탭 - 이전
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    } else {
      // 오른쪽 탭 - 다음
      if (_currentIndex < _itemCount - 1) {
        setState(() => _currentIndex++);
      }
    }
  }

  void _onCommentsTap(BuildContext context, bool autofocus) async {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSize = (screenHeight - topPadding) / screenHeight;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        snap: true,
        snapAnimationDuration: Duration(milliseconds: 200),
        snapSizes: [maxSize],
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: maxSize,
        builder: (context, scrollController) => CommentsSheet(
          scrollController: scrollController,
          autofocus: autofocus,
        ),
      ),
    );
  }

  void _onCloseTap() {
    context.pop();
  }

  void _onPostTap() {
    context.push(PostingAlbumScreen.routeUrl);
  }

  void _onMoreTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SheetSelect(
        items: [
          SheetItem(title: "Delete Post", onTap: () {}, isDestructive: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTapUp: _onTapUp,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "texsdfsdfklsjdfklsdjfklsdjft",
                        style: TextStyle(color: Colors.white),
                      ),
                      Gaps.v16,
                      GestureDetector(
                        onTap: _onPostTap,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Paddings.buttonH,
                            vertical: Paddings.buttonV,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(RValues.button),
                          ),
                          child: Text("New Post"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
                  child: Column(
                    children: [
                      IndexIndicator(currentIndex: _currentIndex),
                      Gaps.v8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Monday",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "Week24",
                                  style: TextStyle(
                                    fontSize: Sizes.size12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            spacing: Sizes.size24,
                            children: [
                              GestureDetector(
                                onTap: _onMoreTap,
                                child: FaIcon(
                                  FontAwesomeIcons.ellipsis,
                                  size: Sizes.size20,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: _onPostTap,
                                child: FaIcon(
                                  FontAwesomeIcons.circlePlus,
                                  size: Sizes.size20,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: _onCloseTap,
                                child: FaIcon(
                                  FontAwesomeIcons.circleXmark,
                                  size: Sizes.size20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    PostCommentBubble(
                      content:
                          "Contents of CommentCommentCommentCommentComment",
                      onTap: () => _onCommentsTap(context, false),
                    ),
                    Gaps.v16,
                    PostBottomBar(
                      nickname: "Bogus",
                      date: "yesterday",
                      likeCount: 3,
                      commentCount: 4,
                      likedUsers: ["Alice", "Bob", "Charlie"],
                      onCommentTap: () => _onCommentsTap(context, true),
                    ),
                    Gaps.v16,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
