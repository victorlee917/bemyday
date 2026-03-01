import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TileBrowse extends StatelessWidget {
  const TileBrowse({
    super.key,
    required this.title,
    this.subTitle,
    required this.url,
  });

  final String title;
  final String? subTitle;
  final String url;

  Future<void> _onBrowseTap(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
      onTap: () => _onBrowseTap(url),
    );
  }
}
