import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: GoogleFonts.darumadropOne(fontSize: Sizes.size28),
            textAlign: TextAlign.center,
          ),
          Gaps.v24,
        ],
      ),
    );
  }
}
