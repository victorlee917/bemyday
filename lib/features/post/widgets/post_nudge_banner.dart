import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

/// 포스트 추가 넛지 배너 - "Make {nickname}'s day!"
class PostNudgeBanner extends StatelessWidget {
  const PostNudgeBanner({
    super.key,
    required this.nickname,
    required this.onTap,
  });

  final String nickname;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.scaffoldH,
          vertical: Paddings.scaffoldV,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RValues.island),
          child: BackdropFilter(
            filter: Blurs.backdrop,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Paddings.bannerH,
                vertical: Paddings.bannerV,
              ),
              decoration: BoxDecoration(
                color: Blurs.overlayColor,
                borderRadius: BorderRadius.circular(RValues.island),
                border: Border.all(color: CustomColors.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Make $nickname's day!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Sizes.size14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Gaps.h10,
                  Text(
                    "Add post",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Sizes.size12,
                      fontWeight: FontWeight.w600,
                    ),
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
