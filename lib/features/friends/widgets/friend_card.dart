import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/friends/widgets/stat_column.dart';
import 'package:flutter/material.dart';

class FriendCard extends StatelessWidget {
  const FriendCard({super.key, required this.weekday});

  final String weekday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.size16,
        vertical: Sizes.size16,
      ),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 24, child: Text("B")),
                  Gaps.h12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bogus",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "since YYYY-MM-DD",
                        style: TextStyle(
                          fontSize: Sizes.size10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Gaps.v16,
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StatColumn(title: "Weeks", stat: 24),
                VerticalDivider(
                  width: Sizes.size64,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                StatColumn(title: "Streaks", stat: 6),
                VerticalDivider(
                  width: Sizes.size64,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                StatColumn(title: "Posts", stat: 23),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
