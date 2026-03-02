import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DropdownButton extends StatelessWidget {
  const DropdownButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.dropdownH,
          vertical: Paddings.dropdownV,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isLoading
                    ? (isDarkMode(context)
                        ? CustomColors.hintColorDark
                        : CustomColors.hintColorLight)
                    : null,
              ),
            ),
            SizedBox(width: Sizes.size6),
            if (isLoading)
              SizedBox(
                width: Sizes.size10,
                height: Sizes.size10,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FaIcon(FontAwesomeIcons.chevronDown, size: Sizes.size10),
          ],
        ),
      ),
    );
  }
}
