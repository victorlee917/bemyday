import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class TileAvatar extends StatelessWidget {
  const TileAvatar({super.key, required this.nickname, this.descripton});

  final String nickname;
  final String? descripton;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Heights.tileItem,
      leading: AvatarDefault(
        nickname: nickname,
        radius: CustomSizes.avatarTile,
      ),
      title: Text(nickname, style: Theme.of(context).textTheme.labelMedium),
      subtitle: descripton != null ? Text(descripton!) : null,
    );
  }
}
