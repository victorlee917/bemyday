import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/confirm_dialog.dart';
import 'package:bemyday/common/widgets/tile/tile_act.dart';
import 'package:bemyday/common/widgets/tile/tile_browse.dart';
import 'package:bemyday/common/widgets/tile/tile_navigate.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/alarm/alarm_screen.dart';
import 'package:bemyday/features/language/language_screen.dart';
import 'package:bemyday/features/profile/profile_screen.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/theme/theme_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key, required this.bottomPadding});
  static const routeName = "my";
  static const routeUrl = "/my";
  final double bottomPadding;

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  void _onDeleteAccountTap() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '계정 삭제',
      message: '정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
      cancelLabel: '취소',
      confirmLabel: '삭제',
      isDestructive: true,
    );
    if (confirmed == true) {
      // TODO: 계정 삭제 로직 구현
    }
  }

  void _onProfileTap() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    context.push(ProfileScreen.routeUrl, extra: profile);
  }

  void _onLogoutTap() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '로그아웃',
      message: '로그아웃 하시겠습니까?',
      cancelLabel: '취소',
      confirmLabel: '로그아웃',
      isDestructive: true,
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final nickname = profile?.nickname ?? "profile";
    final avatar = profile?.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: Text("MY")),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: Paddings.scaffoldH,
          right: Paddings.scaffoldH,
          top: Paddings.profileV,
          bottom: widget.bottomPadding,
        ),
        child: Column(
          children: [
            AvatarDefault(nickname: nickname, avatarUrl: avatar),
            CustomSizes.profileBSpacing,
            Text(
              nickname,
              style: GoogleFonts.darumadropOne(
                textStyle: TextStyle(fontSize: Sizes.size32),
              ),
              textAlign: TextAlign.center,
            ),
            Gaps.v8,
            GestureDetector(
              onTap: _onProfileTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizes.size8,
                  vertical: Sizes.size6,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? CustomColors.clickableAreaDark
                      : CustomColors.clickableAreaLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDarkMode(context)
                        ? CustomColors.borderDark
                        : CustomColors.borderLight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.pencil, size: Sizes.size10),
                      Gaps.h6,
                      Text("Edit", style: TextStyle(fontSize: Sizes.size10)),
                    ],
                  ),
                ),
              ),
            ),
            Gaps.v24,
            Column(
              spacing: CustomSizes.sectionGap,
              children: [
                TilesSection(
                  title: "App",
                  items: [
                    TileNavigate(
                      title: "Alarm",
                      destination: AlarmScreen.routeUrl,
                    ),
                    TileNavigate(
                      title: "Theme",
                      destination: ThemeScreen.routeUrl,
                    ),
                    TileNavigate(
                      title: "Language",
                      destination: LanguageScreen.routeUrl,
                    ),
                  ],
                ),
                TilesSection(
                  title: "BMD",
                  items: [
                    TileBrowse(
                      title: "Instagram",
                      url: "https://www.instagram.com/bemyday.app",
                    ),
                    TileBrowse(
                      title: "Privacy Policy",
                      url: "https://www.bemyday.app/privacy",
                    ),
                    TileBrowse(
                      title: "Terms of Service",
                      url: "https://www.bemyday.app/terms",
                    ),
                    TileAct(title: "Open Source License", action: () {}),
                  ],
                ),
                TilesSection(
                  title: "Danger Zone",
                  items: [
                    TileAct(title: "Logout", action: _onLogoutTap),
                    TileAct(
                      title: "Delete Account",
                      action: _onDeleteAccountTap,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
