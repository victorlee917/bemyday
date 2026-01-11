import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/home/widgets/more_button.dart';
import 'package:bemyday/features/home/widgets/post_stack.dart';
import 'package:flutter/material.dart';

class WeekdayOccupied extends StatefulWidget {
  const WeekdayOccupied({super.key, required this.weekdayIndex});

  final int weekdayIndex;

  @override
  State<WeekdayOccupied> createState() => _WeekdayOccupiedState();
}

class _WeekdayOccupiedState extends State<WeekdayOccupied> {
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Gaps.v32,
        CircleAvatar(radius: Sizes.size36, child: Text("B")),
        Gaps.v16,
        Text(
          "Bogus is\nMy ${_days[widget.weekdayIndex]}",
          style: TextStyle(fontSize: Sizes.size24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Gaps.v24,
        Text("Week 24"),
        Gaps.v12,
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Sizes.size14,
            vertical: Sizes.size6,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            "72h Left",
            style: TextStyle(color: Colors.white, fontSize: Sizes.size12),
          ),
        ),
        Gaps.v24,
        Expanded(child: Center(child: PostStack())),
        Gaps.v20,
        MoreButton(),
        Gaps.v6,
      ],
    );
  }
}
