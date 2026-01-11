import 'package:bemyday/constants/gaps.dart';
import 'package:flutter/material.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key, required this.bottomPadding});
  final double bottomPadding;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: Text("MY")),
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: Column(
                children: [
                  Gaps.v32,
                  CircleAvatar(radius: 36, child: Text("B")),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
