import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StartButton extends StatelessWidget {
  final String label;
  final FaIcon icon;
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
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Paddings.buttonV,
          horizontal: Paddings.buttonH,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(RValues.button),
        ),
        child: Row(
          children: [
            icon,
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
