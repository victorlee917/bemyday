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

/// 카운트다운 포맷: "Xd Xh Xm Xs". 선행 0 단위는 생략.
///
/// 예:
/// - 0d 13h 32m 12s → "13h 32m 12s"
/// - 0d 0h 32m 12s → "32m 12s"
/// - 0d 0h 0m 12s → "12s"
String formatCountdown(Duration duration) {
  if (duration.isNegative) return '0s';
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  final parts = <String>[];
  if (days > 0) parts.add('${days}d');
  if (days > 0 || hours > 0) parts.add('${hours}h');
  if (days > 0 || hours > 0 || minutes > 0) parts.add('${minutes}m');
  parts.add('${seconds}s');

  return parts.join(' ');
}

/// 앱 스타일 스낵바: scaffoldH/V 패딩, RValues.button, 블러, 테두리, 텍스트 가운데 정렬
void showAppSnackBar(BuildContext context, String message) {
  final dark = isDarkMode(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      hitTestBehavior: HitTestBehavior.opaque,
      margin: EdgeInsets.fromLTRB(
        Paddings.scaffoldH,
        Paddings.scaffoldV,
        Paddings.scaffoldH,
        // 네비게이션 바(60) + 여유(20) 위에 표시해 탭 영역 확보
        Paddings.scaffoldV + 84,
      ),
      padding: EdgeInsets.zero,
      content: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
          borderRadius: BorderRadius.circular(RValues.button),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
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
    ),
  );
}
