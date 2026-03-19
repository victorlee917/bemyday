import 'dart:ui';

import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// 상대 시간 표시 (예: "2d ago", "yesterday")
String formatTimeAgo(DateTime dateTime, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return l10n.timeAgoNow;
  if (diff.inMinutes < 60) return l10n.timeAgoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeAgoHours(diff.inHours);
  if (diff.inDays == 1) return l10n.timeAgoYesterday;
  if (diff.inDays < 7) return l10n.timeAgoDays(diff.inDays);
  if (diff.inDays < 30) return l10n.timeAgoWeeks(diff.inDays ~/ 7);
  return l10n.timeAgoMonths(diff.inDays ~/ 30);
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
///
/// [hasBottomNavBar]: true면 네비 바(60) + 여유(24) 위에 표시.
/// false면 화면 최하단(safe area + scaffoldV).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool hasBottomNavBar = true,
}) {
  final dark = isDarkMode(context);
  final mq = MediaQuery.of(context);
  final bottomMargin = hasBottomNavBar
      ? Paddings.scaffoldV + 84 // 네비게이션 바(60) + 여유(24)
      : Paddings.scaffoldV + mq.padding.bottom;
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
        bottomMargin,
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
