import 'package:flutter/material.dart';

void main() {
  runApp(const BeMyDay());
}

class BeMyDay extends StatelessWidget {
  const BeMyDay({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be My Day',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Container(),
    );
  }
}
