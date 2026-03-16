import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TileAct extends StatelessWidget {
  const TileAct({
    super.key,
    required this.action,
    required this.title,
    this.subTitle,
    this.isDestructive = false,
  });

  final String title;
  final String? subTitle;
  final VoidCallback action;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Heights.tileItem,
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: isDestructive
              ? isDarkMode(context)
                    ? CustomColors.destructiveColorDark
                    : CustomColors.destructiveColorLight
              : null,
        ),
      ),
      subtitle: subTitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: Sizes.size4),
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  subTitle!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            )
          : null,
      onTap: action,
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: CustomSizes.tileTrailingIcon,
      ),
    );
  }
}
