import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
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
    return SheetSelect(
      items: [
        SheetItem(title: 'Edit Photo', onTap: onEditTap),
        if (hasImage)
          SheetItem(
            title: 'Delete Photo',
            isDestructive: true,
            onTap: onDeleteTap,
          ),
      ],
    );
  }
}
