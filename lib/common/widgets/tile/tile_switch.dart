import 'package:bemyday/constants/gaps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TileSwitch extends StatelessWidget {
  const TileSwitch({
    super.key,
    required this.title,
    this.subTitle,
    required this.value,
    required this.action,
  });

  final String title;
  final String? subTitle;
  final bool value;
  final ValueChanged<bool> action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            if (subTitle != null) ...[
              Gaps.v4,
              Opacity(
                opacity: 0.5,
                child: Text(
                  subTitle!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ],
        ),
        CupertinoSwitch(
          value: value,
          onChanged: action,
          activeTrackColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
