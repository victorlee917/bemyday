import 'dart:convert';

import 'package:bemyday/config/supabase_config.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/start/widgets/start_button.dart';
import 'package:bemyday/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

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
          showAppSnackBar(context, '로그인이 완료되지 않았습니다. 다시 시도해 주세요.');
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
      // 유저 취소/닫기(canceled, notHandled)는 스낵바 표시 안 함
      const _noSnackBarCodes = {
        AuthorizationErrorCode.canceled,
        AuthorizationErrorCode.notHandled,
      };
      if (!_noSnackBarCodes.contains(e.code) && context.mounted) {
        showAppSnackBar(context, e.message);
      }
    } catch (e) {
      // 유저 취소가 다른 예외로 올 수 있음 (예: "cancel", "cancelled", "notHandled" 등)
      final msg = e.toString().toLowerCase();
      final isUserDismissed =
          msg.contains('cancel') ||
          msg.contains('cancelled') ||
          msg.contains('nothandled') ||
          msg.contains('not handled');
      if (!isUserDismissed && context.mounted) {
        showAppSnackBar(context, 'Apple sign in failed: $e');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? googleIosClientId
            : null,
        serverClientId: googleWebClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Could not get ID token from Google');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Google sign in failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? CustomColors.backgroundColorDark
          : CustomColors.backgroundColorLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: Column(
            children: [
              Expanded(
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
                              "Besties who make my day",
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
              Padding(
                padding: EdgeInsets.only(top: Sizes.size16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                      GestureDetector(
                        onTap: () => _signInWithApple(context),
                        child: StartButton(
                          bgColor: Colors.white,
                          textColor: Colors.black,
                          icon: Image.asset(
                            'assets/icons/apple_logo.png',
                            fit: BoxFit.contain,
                          ),
                          label: "Continue with Apple",
                        ),
                      ),
                      Gaps.v16,
                    ],
                    GestureDetector(
                      onTap: () => _signInWithGoogle(),
                      child: StartButton(
                        bgColor: Color.fromRGBO(242, 242, 242, 1.0),
                        textColor: Colors.black,
                        icon: Image.asset(
                          'assets/icons/google_logo.png',
                          fit: BoxFit.contain,
                        ),
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
                                      launchUrl(
                                        Uri.parse(
                                          "https://www.bemyday.app/privacy",
                                        ),
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
                                      launchUrl(
                                        Uri.parse(
                                          "https://www.bemyday.app/terms",
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
