import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/friends/widgets/friend_card.dart';
import 'package:flutter/material.dart';

class WeekdayFrame extends StatelessWidget {
  const WeekdayFrame({super.key, required this.weekday});

  final Weekday weekday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sizes.size24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weekday.name,
                style: TextStyle(
                  fontSize: Sizes.size28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizes.size12,
                  vertical: Sizes.size8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "3d left",
                  style: TextStyle(color: Colors.white, fontSize: Sizes.size10),
                ),
              ),
            ],
          ),
          Gaps.v12,
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 1,
            itemBuilder: (context, index) => FriendCard(weekday: weekday.name),
            separatorBuilder: (context, index) => Gaps.v16,
          ),
        ],
      ),
    );
  }
}
