import 'dart:convert';

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

  /// 바텀시트 등 GoRouter가 context 상위에 없을 때 전달. 있으면 router.go() 사용.
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
          showAppSnackBar(context, '로그인이 완료되지 않았습니다. 다시 시도해 주세요.');
        }
      });
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_isSigningIn) return;
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
            onTimeout: () =>
                throw Exception('로그인 요청이 시간 초과되었습니다 (30초)'),
          );
      if (response.session == null) {
        throw Exception('세션이 생성되지 않았습니다');
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
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
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
        throw Exception('Google ID 토큰을 받지 못했습니다');
      }

      final response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('로그인 요청이 시간 초과되었습니다 (30초)'),
          );
      if (response.session == null) {
        throw Exception('세션이 생성되지 않았습니다');
      }
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
    setState(() => _isSigningIn = true);
    try {
      // 카카오톡 앱이 있으면 카카오톡으로 로그인, 없으면 OAuth(웹) 폴백
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
                      throw Exception('로그인 요청이 시간 초과되었습니다 (30초)'),
                );
            if (response.session == null) {
              throw Exception('세션이 생성되지 않았습니다');
            }
            if (context.mounted) {
              _navigateAfterLogin(context);
            }
            return;
          }
        } catch (_) {
          // 카카오톡 미설치/취소 등 → OAuth 폴백
        }
      }

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb ? null : 'com.bemyday://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // OAuth는 브라우저에서 완료 후 com.bemyday://login-callback으로 앱 복귀.
    } catch (e) {
      if (mounted) _showLoginError('카카오: $e');
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
            Expanded(
              child: Center(
                child: Padding(
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
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: Paddings.scaffoldV,
                left: Paddings.scaffoldH,
                right: Paddings.scaffoldH,
                bottom: Paddings.scaffoldV,
              ),
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
                  Gaps.v16,
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
