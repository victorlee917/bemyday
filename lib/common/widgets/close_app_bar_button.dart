import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// AppBar actions용 닫기 버튼 (circleXmark)
class CloseAppBarButton extends StatelessWidget {
  const CloseAppBarButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: FaIcon(FontAwesomeIcons.circleXmark, size: Sizes.size20),
      ),
    );
  }
}
