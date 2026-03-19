import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class PostCountBadge extends StatelessWidget {
  const PostCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final fgColor = dark ? Colors.white : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.size20),
      child: BackdropFilter(
        filter: Blurs.backdrop,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Sizes.size12,
            vertical: Sizes.size6,
          ),
          decoration: BoxDecoration(
            color: dark ? Blurs.overlayColorDark : Blurs.overlayColorLight,
            borderRadius: BorderRadius.circular(Sizes.size20),
            border: Border.all(
              color: dark ? CustomColors.borderDark : CustomColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: fgColor,
                  fontSize: Sizes.size14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: Sizes.size4),
              Icon(Icons.arrow_forward, color: fgColor, size: Sizes.size14),
            ],
          ),
        ),
      ),
    );
  }
}
