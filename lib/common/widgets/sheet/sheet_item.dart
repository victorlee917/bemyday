import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SheetItem extends StatelessWidget {
  const SheetItem({
    super.key,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        context.pop();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.buttonH,
          vertical: Paddings.buttonV,
        ),
        decoration: BoxDecoration(
          color: isDarkMode(context)
              ? CustomColors.clickableAreaDark
              : CustomColors.clickableAreaLight,
          borderRadius: BorderRadius.circular(RValues.button),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: isDestructive
                ? isDarkMode(context)
                      ? CustomColors.destructiveColorDark
                      : CustomColors.destructiveColorLight
                : null,
          ),
        ),
      ),
    );
  }
}
