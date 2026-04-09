import 'dart:convert';

import 'package:bemyday/common/widgets/confirm_dialog.dart';
import 'package:bemyday/config/supabase_config.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/start/widgets/start_button.dart';
import 'package:bemyday/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    this.authErrorRetry = false,
    this.inviteToken,
    this.router,
  });
  static const routeName = "start";
  static const routeUrl = "/start";

  final bool authErrorRetry;
  final String? inviteToken;

  /// Pass when GoRouter is not above context (e.g. bottom sheet). Uses router.go() if set.
  final GoRouter? router;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isSigningIn = false;

  void _navigateAfterLogin(BuildContext context) {
    final token =
        widget.inviteToken ??
        (widget.router == null
            ? GoRouterState.of(context).uri.queryParameters['invite_token']
            : null);
    final path = token != null && token.isNotEmpty
        ? '/home?invitation_token=$token'
        : '/home';

    if (widget.router != null) {
      widget.router!.go(path);
    } else {
      context.go(path);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.authErrorRetry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAppSnackBar(
            context,
            'Sign-in was not completed. Please try again.',
          );
        }
      });
    }
  }

  /// Record EULA acceptance in user metadata
  Future<void> _recordEulaAcceptance() async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'eula_accepted_at': DateTime.now().toIso8601String()},
        ),
      );
    } catch (_) {
      // Non-critical — don't block login
    }
  }

  /// EULA agreement dialog. Returns true if agreed, false if cancelled.
  Future<bool> _confirmEula() async {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium!.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    final normalStyle = theme.textTheme.bodyMedium!;

    final privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://www.bemyday.app/privacy'));
      };
    final termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://www.bemyday.app/terms'));
      };

    final agreed = await showConfirmDialog(
      context,
      title: '',
      content: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: [
            TextSpan(
              text: 'By continuing, you agree to BMD\'s\n',
              style: normalStyle,
            ),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: privacyRecognizer,
            ),
            TextSpan(text: ' and ', style: normalStyle),
            TextSpan(
              text: 'Terms of Service (EULA)',
              style: linkStyle,
              recognizer: termsRecognizer,
            ),
            TextSpan(text: '.', style: normalStyle),
          ],
        ),
      ),
      confirmLabel: 'Agree',
      cancelLabel: 'Cancel',
    );

    privacyRecognizer.dispose();
    termsRecognizer.dispose();

    return agreed == true;
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_isSigningIn) return;
    if (!await _confirmEula()) return;
    setState(() => _isSigningIn = true);
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

      final response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            nonce: rawNonce,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Sign-in request timed out (30s)'),
          );
      if (response.session == null) {
        throw Exception('Session was not created');
      }

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
      await _recordEulaAcceptance();
      if (context.mounted) {
        _navigateAfterLogin(context);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      const noSnackBarCodes = {
        AuthorizationErrorCode.canceled,
        AuthorizationErrorCode.notHandled,
      };
      if (!noSnackBarCodes.contains(e.code) && mounted) {
        _showLoginError('Apple: ${e.message}');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isUserDismissed =
          msg.contains('cancel') ||
          msg.contains('cancelled') ||
          msg.contains('nothandled') ||
          msg.contains('not handled');
      if (!isUserDismissed && mounted) {
        _showLoginError('Apple: $e');
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showLoginError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign-in Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    if (!await _confirmEula()) return;
    setState(() => _isSigningIn = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? googleIosClientId
            : null,
        serverClientId: googleWebClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // user cancelled: finally will reset _isSigningIn
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Could not retrieve Google ID token');
      }

      final response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Sign-in request timed out (30s)'),
          );
      if (response.session == null) {
        throw Exception('Session was not created');
      }
      await _recordEulaAcceptance();
      if (context.mounted) {
        _navigateAfterLogin(context);
      }
    } on AuthException catch (e) {
      if (mounted) _showLoginError('Google: ${e.message}');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isUserDismissed =
          (e is PlatformException &&
              (e.code == 'sign_in_canceled' ||
                  e.code == 'sign_in_cancelled')) ||
          msg.contains('cancel') ||
          msg.contains('cancelled');
      if (!isUserDismissed && mounted) {
        _showLoginError('Google: $e');
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithKakao() async {
    if (_isSigningIn) return;
    if (!await _confirmEula()) return;
    setState(() => _isSigningIn = true);
    try {
      // Try KakaoTalk app login first, fall back to OAuth (web) if unavailable
      if (!kIsWeb && kakaoNativeAppKey.isNotEmpty) {
        try {
          final token = await UserApi.instance.loginWithKakaoTalk();
          final idToken = token.idToken;
          if (idToken != null) {
            final response = await Supabase.instance.client.auth
                .signInWithIdToken(
                  provider: OAuthProvider.kakao,
                  idToken: idToken,
                )
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () =>
                      throw Exception('Sign-in request timed out (30s)'),
                );
            if (response.session == null) {
              throw Exception('Session was not created');
            }
            await _recordEulaAcceptance();
            if (context.mounted) {
              _navigateAfterLogin(context);
            }
            return;
          }
        } catch (_) {
          // KakaoTalk not installed / cancelled → OAuth fallback
        }
      }

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb ? null : 'com.bemyday://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // OAuth completes in browser, then returns to app via com.bemyday://login-callback
    } catch (e) {
      if (mounted) _showLoginError('Kakao: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final stackChildren = <Widget>[
      SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
            // Gap between title and buttons. Adjust flex values (top Spacer flex:2 / bottom flex:3)
            const Spacer(flex: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    GestureDetector(
                      onTap: () => _signInWithApple(context),
                      child: StartButton(
                        bgColor: isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        textColor: isDarkMode(context)
                            ? Colors.black
                            : Colors.white,
                        icon: Image.asset(
                          isDarkMode(context)
                              ? 'assets/icons/apple_logo_dark.png'
                              : 'assets/icons/apple_logo_light.png',
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
                  Gaps.v16,
                  GestureDetector(
                    onTap: () => _signInWithKakao(),
                    child: StartButton(
                      bgColor: Color.fromRGBO(255, 230, 23, 1.0),
                      textColor: Colors.black,
                      icon: Image.asset(
                        'assets/icons/kakao_logo.png',
                        fit: BoxFit.contain,
                      ),
                      label: "Continue with Kakao",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
    if (_isSigningIn) {
      stackChildren.add(
        Positioned.fill(
          child: ColoredBox(
            color:
                (dark
                        ? CustomColors.backgroundColorDark
                        : CustomColors.backgroundColorLight)
                    .withValues(alpha: 0.9),
            child: const Center(child: CircularProgressIndicator.adaptive()),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: dark
          ? CustomColors.backgroundColorDark
          : CustomColors.backgroundColorLight,
      body: Stack(children: stackChildren),
    );
  }
}
