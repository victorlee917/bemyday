import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Title",
            style: GoogleFonts.darumadropOne(fontSize: Sizes.size36),
          ),
          Gaps.v2,
          Opacity(
            opacity: 0.5,
            child: Text(
              "subTitle",
              style: GoogleFonts.darumadropOne(fontSize: Sizes.size16),
            ),
          ),
          Gaps.v24,
        ],
      ),
    );
  }
}
