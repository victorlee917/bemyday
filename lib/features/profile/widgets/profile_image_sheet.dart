import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileImageSheet extends StatelessWidget {
  const ProfileImageSheet({
    super.key,
    required this.hasImage,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final bool hasImage;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SheetSelect(
      items: [
        SheetItem(title: l10n.profileEditPhoto, onTap: onEditTap),
        if (hasImage)
          SheetItem(
            title: l10n.profileDeletePhoto,
            isDestructive: true,
            onTap: onDeleteTap,
          ),
      ],
    );
  }
}
