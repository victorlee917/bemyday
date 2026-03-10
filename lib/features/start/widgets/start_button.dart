import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

/// Apple Sign in with Apple 가이드라인: 최소 44pt, 로그인 버튼은 48pt 권장
class StartButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color bgColor;
  final Color textColor;

  const StartButton({
    super.key,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.hardEdge,
            constraints: const BoxConstraints(minHeight: Sizes.size48),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(RValues.button),
              border: Border.all(
                color: isDarkMode(context)
                    ? CustomColors.borderDark
                    : CustomColors.borderLight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge!.copyWith(color: textColor),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: SizedBox(
                    width: Sizes.size48,
                    height: Sizes.size48,
                    child: FittedBox(fit: BoxFit.contain, child: icon),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
