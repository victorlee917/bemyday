import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class TilesSection extends StatelessWidget {
  const TilesSection({super.key, this.title, required this.items});

  final String? title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Gaps.h20,
              Text(title!, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          CustomSizes.sectionTitleGap,
        ],
        Container(
          decoration: BoxDecoration(
            color: dark
                ? CustomColors.clickableAreaDark
                : CustomColors.clickableAreaLight,
            borderRadius: BorderRadius.circular(RValues.island),
            border: Border.all(
              color: dark ? CustomColors.borderDark : CustomColors.borderLight,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.tileH,
            vertical: Paddings.tileV,
          ),
          child: Column(
            spacing: CustomSizes.tileSpacing,
            children: [for (var item in items) item],
          ),
        ),
      ],
    );
  }
}
