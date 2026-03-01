import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({super.key, this.group});

  final Group? group;

  void _onMoreTap(BuildContext context) {
    context.push(PartyScreen.routeUrl, extra: group);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onMoreTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.size6,
          vertical: Sizes.size4,
        ),
        decoration: BoxDecoration(
          color: isDarkMode(context)
              ? CustomColors.clickableAreaDark
              : CustomColors.clickableAreaLight,
          borderRadius: BorderRadius.circular(Sizes.size32),
        ),
        child: Opacity(
          opacity: 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(
                Icons.circle,
                size: Sizes.size4,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
              Icon(
                Icons.circle,
                size: Sizes.size4,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
              Icon(
                Icons.circle,
                size: Sizes.size4,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
