import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/utils.dart';
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
            opacity: isSelected ? 1 : 0.3,
            duration: Duration(milliseconds: 100),
            child: FaIcon(
              icon,
              color: isDarkMode(context) ? Colors.white : Colors.black,
              size: Sizes.size24,
            ),
          ),
        ),
      ),
    );
  }
}
