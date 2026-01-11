import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class VacantButton extends StatelessWidget {
  const VacantButton({super.key, required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          Gaps.v12,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Paddings.buttonH,
              vertical: Paddings.buttonV,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(label, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
