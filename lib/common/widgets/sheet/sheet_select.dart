import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class SheetSelect extends StatelessWidget {
  const SheetSelect({
    super.key,
    required this.items,
    this.maxHeight,
    this.isDarkOnly = false,
  });

  final List<Widget> items;
  final double? maxHeight;
  final bool isDarkOnly;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkOnly || isDarkMode(context)
        ? CustomColors.sheetColorDark
        : CustomColors.sheetColorLight;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : CustomSizes.tileSpacing,
            ),
            child: item,
          );
        }),
      ],
    );

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Container(
            constraints: maxHeight != null
                ? BoxConstraints(maxHeight: maxHeight!)
                : null,
            padding: EdgeInsets.only(
              left: Paddings.scaffoldH,
              right: Paddings.scaffoldH,
              top: Sizes.size16,
              bottom: Sizes.size16,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(RValues.bottomsheet),
              ),
            ),
            child: maxHeight != null
                ? SingleChildScrollView(child: content)
                : content,
          ),
        ),
      ),
    );
  }
}
