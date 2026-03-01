import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class IndexIndicator extends StatelessWidget {
  const IndexIndicator({
    super.key,
    this.itemCount = 5,
    required this.currentIndex,
  });

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: List.generate(itemCount * 2 - 1, (i) {
              if (i.isOdd) return Gaps.h4; // separator
              return Expanded(
                child: Container(
                  height: 2, // 원하는 높이로
                  decoration: BoxDecoration(
                    color: currentIndex == i / 2
                        ? Colors.white
                        : Color.fromRGBO(255, 255, 255, 0.3),
                    borderRadius: BorderRadius.circular(Sizes.size36),
                  ),
                ),
              );
            }),
          ),
          Gaps.v2,
        ],
      ),
    );
  }
}
