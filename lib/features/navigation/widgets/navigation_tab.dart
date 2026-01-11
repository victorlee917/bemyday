import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NavigationTab extends StatelessWidget {
  const NavigationTab({
    super.key,
    required this.text,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final IconData icon;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(),
        behavior: HitTestBehavior.opaque, // 빈 공간도 탭 가능하게
        child: Center(
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0.6,
            duration: Duration(milliseconds: 100),
            child: FaIcon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
