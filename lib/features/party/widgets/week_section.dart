import 'package:bemyday/common/widgets/thumbnail_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WeekSection extends StatelessWidget {
  const WeekSection({super.key, required this.week});

  final int week;

  void _onPostTap(BuildContext context) {
    context.push(PostScreen.routeUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: Paddings.scaffoldH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Week $week", style: Theme.of(context).textTheme.titleSmall),
              Opacity(
                opacity: 0.5,
                child: Text(
                  "36 post",
                  style: TextStyle(fontSize: Sizes.size12),
                ),
              ),
            ],
          ),
        ),
        CustomSizes.sectionTitleGap,
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
            itemCount: 1000,
            separatorBuilder: (_, __) => Gaps.h12,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _onPostTap(context),
                child: ThumbnailDefault(),
              );
            },
          ),
        ),
      ],
    );
  }
}
