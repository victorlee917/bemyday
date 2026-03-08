import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 그룹이 없을 때 표시하는 빈 상태 공통 위젯
///
/// - [message]: 메인 문구 (예: "Who's your Monday?", "Invite friends to get started")
/// - [onInviteTap]: Invite Friend 버튼 탭 시 호출
/// - [buttonLabel]: 버튼 텍스트 (기본: "Invite Friend")
class VacantPage extends StatelessWidget {
  const VacantPage({
    super.key,
    required this.message,
    this.onInviteTap,
    this.buttonLabel = 'Invite Friends',
  });

  final String message;
  final VoidCallback? onInviteTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(
        horizontal: Paddings.scaffoldH,
        vertical: Paddings.scaffoldV,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.darumadropOne(
                textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              textAlign: TextAlign.center,
            ),
            Gaps.v24,
            GestureDetector(
              onTap: onInviteTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Paddings.buttonH * 2,
                  vertical: Paddings.buttonV,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? CustomColors.clickableAreaDark
                      : CustomColors.clickableAreaLight,
                  borderRadius: BorderRadius.circular(RValues.button),
                  border: Border.all(
                    color: isDarkMode(context)
                        ? CustomColors.borderDark
                        : CustomColors.borderLight,
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
