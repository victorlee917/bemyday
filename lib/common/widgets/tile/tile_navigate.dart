import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart'; // ✅ 추가

class TileNavigate extends StatelessWidget {
  const TileNavigate({
    super.key,
    required this.title,
    this.subTitle,
    required this.destination,
  });

  final String title;
  final String? subTitle;
  final String destination;

  void _onNavigateTap(BuildContext context) {
    context.push(destination);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Heights.tileItem,
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: subTitle != null ? Text(subTitle!) : null,
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: CustomSizes.tileTrailingIcon,
      ),
      onTap: () => _onNavigateTap(context),
    );
  }
}
