import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentInputAvatar extends ConsumerWidget {
  const CommentInputAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      data: (profile) => AvatarDefault(
        nickname: profile?.nickname ?? '?',
        avatarUrl: profile?.avatarUrl,
        radius: Sizes.size16,
      ),
      loading: () => AvatarDefault(nickname: '…', radius: Sizes.size16),
      error: (_, __) => AvatarDefault(nickname: '?', radius: Sizes.size16),
    );
  }
}
