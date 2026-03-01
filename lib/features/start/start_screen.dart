import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/profile/profile_screen.dart';
import 'package:bemyday/features/start/widgets/start_button.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});
  static const routeName = "start";
  static const routeUrl = "/start";

  void _onStart(BuildContext context) {
    context.go(ProfileScreen.routeUrl);
  }

  Future<void> _signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.bemyday://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? CustomColors.backgroundColorDark
          : CustomColors.backgroundColorLight,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Column(
                    children: [
                      Text(
                        "Be My Day",

                        style: GoogleFonts.darumadropOne(
                          textStyle: TextStyle(fontSize: Sizes.size48),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gaps.v2,
                      Opacity(
                        opacity: 0.5,
                        child: Text(
                          "Pals who make my day",
                          style: GoogleFonts.darumadropOne(
                            textStyle: TextStyle(fontSize: Sizes.size16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Sizes.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _onStart(context),
                child: StartButton(
                  bgColor: isDarkMode(context)
                      ? CustomColors.clickableAreaDark
                      : Colors.black,
                  textColor: Colors.white,
                  icon: FaIcon(FontAwesomeIcons.apple, color: Colors.white),
                  label: "Continue with Apple",
                ),
              ),
              Gaps.v16,
              GestureDetector(
                onTap: () => _signInWithGoogle(),
                child: StartButton(
                  bgColor: isDarkMode(context)
                      ? Colors.white
                      : CustomColors.clickableAreaLight,
                  textColor: Colors.black,
                  icon: FaIcon(FontAwesomeIcons.google, color: Colors.black),
                  label: "Continue with Google",
                ),
              ),
              Gaps.v12,
              Opacity(
                opacity: 0.5,
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "By continuing, you agree to BMD's\n",
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // 링크 클릭 시 동작
                                launchUrl(
                                  Uri.parse("https://example.com/terms"),
                                );
                              },
                          ),
                          TextSpan(
                            text: " and ",
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          TextSpan(
                            text: "Terms of Service",
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // 링크 클릭 시 동작
                                launchUrl(
                                  Uri.parse("https://example.com/terms"),
                                );
                              },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// GoogleFonts.belanosima