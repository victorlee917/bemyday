import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LikesSheet extends ConsumerWidget {
  const LikesSheet({super.key, required this.likedUserIds});

  final List<String> likedUserIds;

  void _onCloseTap(BuildContext context) {
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dark = isDarkMode(context);
    final sheetColor =
        dark ? CustomColors.sheetColorDark : CustomColors.sheetColorLight;
    final borderColor =
        dark ? CustomColors.borderDark : CustomColors.borderLight;
    final fgColor = dark ? Colors.white : Colors.black;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: Scaffold(
        backgroundColor: sheetColor,
        appBar: AppBar(
          title: Text(l10n.likesTitle, style: TextStyle(color: fgColor)),
          automaticallyImplyLeading: false,
          backgroundColor: sheetColor,
          shape: Border(
            bottom: BorderSide(
              color: borderColor,
              width: Widths.devider,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => _onCloseTap(context),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.circleXmark,
                  size: Sizes.size20,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
        body: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Paddings.scaffoldV,
          ),
          itemCount: likedUserIds.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: CustomSizes.tileSpacing),
          itemBuilder: (context, index) {
            final userId = likedUserIds[index];
            final profileAsync = ref.watch(profileProvider(userId));
            return profileAsync.when(
              data: (profile) => Row(
                children: [
                  AvatarPackage(
                    nickname: profile?.nickname ?? '?',
                    avatarUrl: profile?.avatarUrl,
                    title: profile?.nickname ?? '?',
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  AvatarPackage(
                    nickname: '…',
                    title: '…',
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  AvatarPackage(
                    nickname: '?',
                    title: '?',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
