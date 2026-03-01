import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class SheetWidget extends StatelessWidget {
  const SheetWidget({
    super.key,
    required this.left,
    required this.onTap,
    this.isDarkOnly = false,
    this.isDimmed = false,
  });

  final Widget left;
  final VoidCallback onTap;
  final bool isDarkOnly;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDimmed
          ? null
          : () {
              context.pop();
              onTap();
            },
      child: Opacity(
        opacity: isDimmed ? 0.5 : 1.0,
        child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.buttonH,
          vertical: Paddings.buttonV,
        ),
        decoration: BoxDecoration(
          color: isDarkOnly || isDarkMode(context)
              ? CustomColors.clickableAreaDark
              : CustomColors.clickableAreaLight,
          borderRadius: BorderRadius.circular(RValues.button),
        ),
        child: Row(
          children: [Expanded(child: left)],
        ),
      ),
    ),
    );
  }
}
