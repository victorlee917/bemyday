import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

/// 로그아웃, 탈퇴 등 재확인이 필요한 상황의 공통 확인 팝업
///
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: '로그아웃',
///   message: '로그아웃 하시겠습니까?',
///   confirmLabel: '로그아웃',
///   isDestructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String cancelLabel = 'Cancel',
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.cancelLabel = 'Cancel',
    required this.confirmLabel,
    this.isDestructive = false,
  });

  final String title;
  final String? message;
  final String cancelLabel;
  final String confirmLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark
        ? CustomColors.sheetColorDark
        : CustomColors.sheetColorLight;
    final destructiveColor = dark
        ? CustomColors.destructiveColorDark
        : CustomColors.destructiveColorLight;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RValues.island),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.scaffoldH,
          vertical: Paddings.scaffoldV,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty) ...[
              Gaps.v10,
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            Gaps.v24,
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Paddings.buttonH,
                        vertical: Paddings.buttonV,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? CustomColors.clickableAreaDark
                            : CustomColors.clickableAreaLight,
                        borderRadius: BorderRadius.circular(RValues.button),
                      ),
                      child: Text(
                        cancelLabel,
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Gaps.h12,
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Paddings.buttonH,
                        vertical: Paddings.buttonV,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? CustomColors.clickableAreaDark
                            : CustomColors.clickableAreaLight,
                        borderRadius: BorderRadius.circular(RValues.button),
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(
                              color: isDestructive ? destructiveColor : null,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
