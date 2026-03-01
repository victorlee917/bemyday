import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/friends/widgets/friend_card.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:flutter/material.dart';

class WeekdaySection extends StatelessWidget {
  const WeekdaySection({
    super.key,
    required this.weekday,
    required this.weekdayIndex,
    this.group,
  });

  final Weekday weekday;
  final int weekdayIndex;
  final Group? group;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(weekday.name, style: Theme.of(context).textTheme.titleLarge),
            TimeleftChip(targetWeekday: weekdayIndex + 1),
          ],
        ),
        CustomSizes.sectionTitleGap,
        FriendCard(weekday: weekday.name, group: group),
      ],
    );
  }
}

// Theme.of(context).textTheme.titleLarge)
