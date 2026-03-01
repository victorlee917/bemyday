import 'package:bemyday/common/widgets/tile/tile_switch.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  static const routeName = "alarm";
  static const routeUrl = "/alarm";

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  bool _newService = false;
  bool _newPost = false;
  bool _newComment = false;
  bool _newLike = false;

  void _onServiceChanged(bool value) {
    setState(() => _newService = value);
  }

  void _onNewPostChanged(bool value) {
    setState(() => _newPost = value);
  }

  void _onNewCommentChanged(bool value) {
    setState(() => _newComment = value);
  }

  void _onNewLikeChanged(bool value) {
    setState(() => _newLike = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alarm")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: Paddings.scaffoldH,
            right: Paddings.scaffoldH,
            top: Paddings.scaffoldV,
          ),
          child: TilesSection(
            items: [
              TileSwitch(
                title: "Be My Day",
                subTitle: "서비스 소식을 안내드려요",
                value: _newService,
                action: _onServiceChanged,
              ),
              TileSwitch(
                title: "New Post",
                value: _newPost,
                action: _onNewPostChanged,
              ),
              TileSwitch(
                title: "New Comment",
                value: _newComment,
                action: _onNewCommentChanged,
              ),
              TileSwitch(
                title: "New Like",
                value: _newLike,
                action: _onNewLikeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
