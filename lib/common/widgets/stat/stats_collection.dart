import 'package:bemyday/common/widgets/stat/stat_column.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

class StatItem {
  final String title;
  final int value;

  const StatItem({required this.title, required this.value});
}

class StatsCollection extends StatelessWidget {
  const StatsCollection({super.key, required this.stats});
  final List<StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Sizes.size48,
      child: Row(
        children: [
          for (var (index, stat) in stats.indexed) ...[
            StatColumn(title: stat.title, value: stat.value),
            if (index < stats.length - 1)
              Container(
                width: Widths.devider,
                height: 32,
                color: isDarkMode(context)
                    ? CustomColors.borderDark
                    : CustomColors.borderLight,
              ),
          ],
        ],
      ),
    );
  }
}
