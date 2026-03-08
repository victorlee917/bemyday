import 'dart:ui';

import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// 상대 시간 표시 (예: "1시간 전", "어제")
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  return '${diff.inDays ~/ 30}mo ago';
}

/// 앱 스타일 스낵바: scaffoldH/V 패딩, RValues.button, 블러, 테두리, 텍스트 가운데 정렬
void showAppSnackBar(BuildContext context, String message) {
  final dark = isDarkMode(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(
        horizontal: Paddings.scaffoldH,
        vertical: Paddings.scaffoldV,
      ),
      padding: EdgeInsets.zero,
      content: GestureDetector(
        onTap: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RValues.button),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: Blurs.sigma, sigmaY: Blurs.sigma),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Paddings.scaffoldH,
                vertical: Paddings.scaffoldV,
              ),
              decoration: BoxDecoration(
                color: (dark ? CustomColors.sheetColorDark : CustomColors.sheetColorLight)
                    .withOpacity(0.75),
                borderRadius: BorderRadius.circular(RValues.button),
                border: Border.all(
                  color: dark ? CustomColors.borderDark : CustomColors.borderLight,
                  width: Widths.devider,
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black,
                  fontSize: Sizes.size14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
