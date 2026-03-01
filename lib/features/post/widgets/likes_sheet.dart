import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class LikesSheet extends StatelessWidget {
  const LikesSheet({super.key, required this.likedUsers});

  final List<String> likedUsers;

  void _onCloseTap(BuildContext context) {
    context.pop();
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
        backgroundColor: CustomColors.sheetColorDark,
        appBar: AppBar(
          title: Text("Likes", style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
          backgroundColor: CustomColors.sheetColorDark,
          shape: Border(
            bottom: BorderSide(
              color: CustomColors.borderDark,
              width: Widths.devider,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => _onCloseTap(context),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.circleXmark,
                  size: Sizes.size20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Paddings.scaffoldV,
          ),
          itemCount: likedUsers.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: CustomSizes.tileSpacing),
          itemBuilder: (context, index) {
            final user = likedUsers[index];
            return Row(
              children: [
                AvatarPackage(nickname: user, title: user, isDarkOnly: true),
              ],
            );
          },
        ),
      ),
    );
  }
}
