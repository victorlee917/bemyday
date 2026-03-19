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
import 'package:bemyday/features/auth/providers/account_repository_provider.dart';
import 'package:bemyday/features/profile/profile_screen.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/license/license_screen.dart';
import 'package:bemyday/features/theme/theme_screen.dart';
import 'package:bemyday/features/tutorial/tutorial_screen.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountMessage,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.delete,
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      if (!mounted) return;
      context.go(TutorialScreen.routeUrl);
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      showAppSnackBar(context, msg.isNotEmpty ? msg : l10n.deleteAccountFailed);
    }
  }

  void _onProfileTap() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    context.push(ProfileScreen.routeUrl, extra: profile);
  }

  void _onLogoutTap() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.myLogout,
      isDestructive: true,
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final nickname = profile?.nickname ?? l10n.profileFallback;
    final avatar = profile?.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTabTitle)),
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
                      Text(l10n.edit, style: TextStyle(fontSize: Sizes.size10)),
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
                  title: l10n.mySectionApp,
                  items: [
                    TileNavigate(
                      title: l10n.myAlarm,
                      destination: AlarmScreen.routeUrl,
                    ),
                    TileNavigate(
                      title: l10n.myTheme,
                      destination: ThemeScreen.routeUrl,
                    ),
                    // TileNavigate(
                    //   title: l10n.myLanguage,
                    //   destination: LanguageScreen.routeUrl,
                    // ),
                  ],
                ),
                TilesSection(
                  title: l10n.mySectionBmd,
                  items: [
                    TileBrowse(
                      title: l10n.myInstagram,
                      url: "https://www.instagram.com/bemyday.app",
                    ),
                    TileBrowse(
                      title: l10n.myPrivacyPolicy,
                      url: "https://www.bemyday.app/privacy",
                    ),
                    TileBrowse(
                      title: l10n.myTermsOfService,
                      url: "https://www.bemyday.app/terms",
                    ),
                    TileNavigate(
                      title: l10n.myOpenSourceLicense,
                      destination: LicenseScreen.routeUrl,
                    ),
                  ],
                ),
                TilesSection(
                  title: l10n.mySectionDangerZone,
                  items: [
                    TileAct(title: l10n.myLogout, action: _onLogoutTap),
                    TileAct(
                      title: l10n.myDeleteAccount,
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
