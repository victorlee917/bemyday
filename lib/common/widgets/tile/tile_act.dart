import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';

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
      subtitle: subTitle != null ? Text(subTitle!) : null,
      onTap: action,
    );
  }
}
