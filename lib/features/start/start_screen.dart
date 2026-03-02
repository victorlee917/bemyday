import 'dart:convert';

import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/start/widgets/start_button.dart';
import 'package:bemyday/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, this.authErrorRetry = false});
  static const routeName = "start";
  static const routeUrl = "/start";

  final bool authErrorRetry;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.authErrorRetry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 완료되지 않았습니다. 다시 시도해 주세요.'),
            ),
          );
        }
      });
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Could not get ID token from Apple');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (credential.givenName != null || credential.familyName != null) {
        final fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        if (fullName.isNotEmpty) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'given_name': credential.givenName,
                'family_name': credential.familyName,
              },
            ),
          );
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Apple sign in failed: $e')));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // 모바일: 브라우저 → Google OAuth → Supabase → bemyday.app/auth/callback → 앱(com.bemyday://login-callback)
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'https://bemyday.app/auth/callback',
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
              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                GestureDetector(
                  onTap: () => _signInWithApple(context),
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
              ],
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
                                  Uri.parse("https://www.bemyday.app/privacy"),
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
                                  Uri.parse("https://www.bemyday.app/terms"),
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