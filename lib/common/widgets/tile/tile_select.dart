import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TileSelect extends StatelessWidget {
  const TileSelect({
    super.key,
    required this.title,
    required this.option,
    required this.selectedOption,
    required this.onTileTap,
    this.subTitle,
  });

  final String title;
  final String? subTitle;
  final String option;
  final String selectedOption;
  final Function onTileTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Heights.tileItem,
      onTap: () => onTileTap(option),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      trailing: option == selectedOption
          ? FaIcon(FontAwesomeIcons.check, size: CustomSizes.tileTrailingIcon)
          : null,
    );
  }
}
