import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPrevious() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _onNext() {
    if (_tabController.index < 2) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: Column(children: [Text("page one")]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: Column(children: [Text("page two")]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: Column(children: [Text("page three")]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabPageSelector(
                controller: _tabController,
                color: Colors.white,
                selectedColor: Colors.black,
              ),
              Row(
                children: [
                  GestureDetector(onTap: _onPrevious, child: Text("previous")),
                  GestureDetector(onTap: _onNext, child: Text("Next")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
