import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/friends/widgets/weekday_frame.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.bottomPadding});
  final double bottomPadding;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text("Friends"),
          automaticallyImplyLeading: false,
          leading: Center(
            child: FaIcon(FontAwesomeIcons.plus, size: Sizes.size20),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final weekday = weekdays[index];
                  return WeekdayFrame(weekday: weekday);
                },
                separatorBuilder: (context, index) => Gaps.v24,
                itemCount: weekdays.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
