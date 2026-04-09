import 'package:app_links/app_links.dart';
import 'package:bemyday/config/supabase_config.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:bemyday/features/invite/repositories/invitation_repository.dart';
import 'package:bemyday/features/push/push_notification_service.dart' deferred as push;
import 'package:bemyday/features/start/start_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/core/providers.dart';
import 'package:bemyday/features/home/providers/realtime_provider.dart';
import 'package:bemyday/features/alarm/providers/alarm_provider.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/profile/providers/profile_repository_provider.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/tutorial/tutorial_screen.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/features/theme/viewmodels/theme_viewmodel.dart';
import 'package:bemyday/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// https://bemyday.app/invitation/:token 또는 com.bemyday://invitation/:token → /invitation/:token
String? _invitePathFromUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.path.startsWith('/invitation/')) return uri.path;
  // 카카오톡 인앱 브라우저용: com.bemyday://invitation/TOKEN
  if (uri.scheme == 'com.bemyday' &&
      uri.host == 'invitation' &&
      uri.pathSegments.isNotEmpty) {
    return '/invitation/${uri.pathSegments.first}';
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await GoogleFonts.pendingFonts([GoogleFonts.darumadropOne()]);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      timeout: Duration(seconds: 30),
      logLevel: RealtimeLogLevel.info,
    ),
  );

  if (kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }

  await push.loadLibrary();
  await push.PushNotificationService.initialize();

  final authStateNotifier = AuthStateNotifier();

  // SharedPreferences 미리 초기화
  final prefs = await SharedPreferences.getInstance();
  // 이전 세션의 pending invite token 항상 제거 (getInitialLink stale 값으로 인한 잘못된 리다이렉트 방지)
  await prefs.remove(pendingInviteTokenKey);

  // 딥링크: 앱이 링크로 실행된 경우 초기 경로 설정 (초대 링크 전용)
  // getInitialLink()는 앱 재시작 후에도 이전 링크를 반환할 수 있으므로, 유효한 초대만 사용
  // 디버그 재시작 시 stale 값으로 잘못된 리다이렉트 방지: release에서만 사용
  // 로그인: /home?invitation_token=TOKEN (바텀시트), 로그아웃: /start?invite_token=TOKEN (로그인 후 시트)
  String? initialLocation;
  try {
    if (!kDebugMode) {
      final initialUri = await AppLinks().getInitialLink();
      final invitePath = _invitePathFromUri(initialUri);
      if (invitePath != null) {
        final token = invitePath.split('/').last;
        final data = await InvitationRepository().getInvitationByToken(token);
        if (data != null) {
          final session = Supabase.instance.client.auth.currentSession;
          initialLocation = session != null
              ? '/home?invitation_token=$token'
              : '${StartScreen.routeUrl}?invite_token=$token';
        }
      }
    }
  } catch (_) {}

  final router = createRouter(
    authStateNotifier,
    initialLocation: initialLocation ?? TutorialScreen.routeUrl,
  );

  // 딥링크: 앱이 백그라운드에서 링크로 열린 경우 (초대 링크 전용)
  AppLinks().uriLinkStream.listen((uri) async {
    final invitePath = _invitePathFromUri(uri);
    if (invitePath == null) return;
    final token = invitePath.split('/').last;
    final data = await InvitationRepository().getInvitationByToken(token);
    if (data == null) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      String currentPath = '/home';
      try {
        final config = router.routerDelegate.currentConfiguration;
        currentPath = config.uri.path;
      } catch (_) {}
      final isNavTab =
          currentPath == '/home' ||
          currentPath == '/friends' ||
          currentPath == '/my';
      router.go(
        isNavTab
            ? '$currentPath?invitation_token=$token'
            : '/home?invitation_token=$token',
      );
    } else {
      router.go('${StartScreen.routeUrl}?invite_token=$token');
    }
  });

  runApp(
    ProviderScope(
      // SharedPreferences를 override하여 주입 (MVVM: Model 레이어에서 사용)
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: BeMyDay(router: router),
    ),
  );
}

class BeMyDay extends ConsumerWidget {
  const BeMyDay({super.key, required this.router});
  final GoRouter router;

  // 공통 텍스트 테마 (light/dark 공용)
  static const textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: Sizes.size28,
      fontWeight: FontWeight.w900,
    ),
    titleLarge: TextStyle(fontSize: Sizes.size20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: Sizes.size16, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(fontSize: Sizes.size14, fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(fontSize: Sizes.size14, fontWeight: FontWeight.w500),
    bodySmall: TextStyle(fontSize: Sizes.size12, fontWeight: FontWeight.w300),
    labelLarge: TextStyle(fontSize: Sizes.size16, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: Sizes.size14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: Sizes.size12, fontWeight: FontWeight.w300),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod으로 테마 상태 구독 (ViewModel Provider 사용)
    final themeMode = ref.watch(themeViewModelProvider);

    // 테마 변경 시 status bar 스타일 동기화 (앱 배경과 맞춤, 회색 방지)
    ref.listen(themeViewModelProvider, (_, mode) {
      final dark = mode == ThemeMode.dark;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dark = themeMode == ThemeMode.dark;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      );
    });

    // 로그인 시 Realtime 구독 (새 게시글/멤버 추가 시 HomeScreen 등 갱신)
    ref.watch(homeRealtimeProvider);

    // 푸시 권한 팝업에서 동의 시 앱 내 모든 알람 ON
    ref.listen(notificationPermissionProvider, (prev, next) {
      next.whenOrNull(
        data: (status) {
          if (status != AuthorizationStatus.authorized) return;
          final wasDenied = prev?.valueOrNull == AuthorizationStatus.denied ||
              prev?.valueOrNull == AuthorizationStatus.notDetermined;
          final wasUnknown = prev?.valueOrNull == null;
          if (wasDenied) {
            ref
                .read(alarmPreferencesProvider.notifier)
                .enableAll()
                .catchError((_) {});
          } else if (wasUnknown) {
            ref.read(alarmPreferencesProvider.future).then((prefs) {
              if (!prefs.dailyReminder &&
                  !prefs.newPost &&
                  !prefs.newComment &&
                  !prefs.newLike) {
                ref
                    .read(alarmPreferencesProvider.notifier)
                    .enableAll()
                    .catchError((_) {});
              }
            });
          }
        },
      );
    });

    // 로그아웃/계정 전환 시 유저별 캐시 무효화 + FCM 토큰 등록/해제
    ref.listen(authStateProvider, (prev, next) {
      final prevUserId = prev?.valueOrNull?.session?.user.id;
      final nextUserId = next.valueOrNull?.session?.user.id;
      if (nextUserId != null) {
        // 세션 유지 재시작 또는 로그인 시 항상 토큰 등록
        push.PushNotificationService.ensureTokenRegistered();
      }
      if (prevUserId != nextUserId) {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(currentUserGroupsProvider);
        ref.invalidate(alarmPreferencesProvider);
        if (nextUserId != null) {
          ref.read(alarmPreferencesProvider.future).then((prefs) {
            push.PushNotificationService.syncDailyReminder(prefs.dailyReminder);
          });
          ref
              .read(profileRepositoryProvider)
              .syncTimezoneToProfile()
              .catchError((_) {});
        } else {
          push.PushNotificationService.unregisterToken();
          push.PushNotificationService.cancelDailyReminder();
        }
      }
    });

    // 공통 AppBar 타이틀 스타일 (색상 제외)
    const appBarTitleStyle = TextStyle(
      fontSize: Sizes.size16,
      fontWeight: FontWeight.w700,
    );

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Be My Day',
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      // 라이트 모드 테마
      theme: ThemeData(
        hintColor: CustomColors.hintColorLight,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(primary: CustomColors.primaryColorLight),
        primaryColor: CustomColors.primaryColorLight,
        scaffoldBackgroundColor: CustomColors.backgroundColorLight,
        cardColor: CustomColors.clickableAreaLight,
        bottomAppBarTheme: BottomAppBarThemeData(
          surfaceTintColor: Colors.transparent,
          color: Colors.transparent,
        ),
        appBarTheme: AppBarTheme(
          surfaceTintColor: CustomColors.backgroundColorLight,
          backgroundColor: CustomColors.backgroundColorLight,
          foregroundColor: Colors.black, //아이콘 색상
          elevation: 0,
          centerTitle: true,
          titleSpacing: Paddings.scaffoldH, // 타이틀 좌측 패딩
          actionsPadding: EdgeInsets.only(
            right: Paddings.scaffoldH,
          ), // actions 우측 패딩
          titleTextStyle: appBarTitleStyle.copyWith(color: Colors.black),
          iconTheme: IconThemeData(size: Sizes.size20),
          actionsIconTheme: IconThemeData(size: Sizes.size20),
          shape: Border(
            bottom: BorderSide(
              color: CustomColors.borderLight,
              width: Widths.devider,
            ),
          ),
        ),
        textTheme: textTheme,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: CustomColors.sheetColorLight,
          contentTextStyle: TextStyle(
            color: Colors.black,
            fontSize: Sizes.size14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RValues.button),
            side: BorderSide(
              color: CustomColors.borderLight,
              width: Widths.devider,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Paddings.scaffoldV,
          ),
        ),
      ),
      // 다크 모드 테마
      darkTheme: ThemeData(
        hintColor: CustomColors.hintColorDark,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(primary: CustomColors.primaryColorDark),
        primaryColor: CustomColors.primaryColorDark,
        scaffoldBackgroundColor: CustomColors.backgroundColorDark,
        cardColor: CustomColors.clickableAreaDark,
        appBarTheme: AppBarTheme(
          surfaceTintColor: CustomColors.backgroundColorDark,
          backgroundColor: CustomColors.backgroundColorDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleSpacing: Paddings.scaffoldH, // 타이틀 좌측 패딩
          actionsPadding: EdgeInsets.only(
            right: Paddings.scaffoldH,
          ), // actions 우측 패딩
          titleTextStyle: appBarTitleStyle.copyWith(color: Colors.white),
          iconTheme: IconThemeData(size: Sizes.size20),
          actionsIconTheme: IconThemeData(size: Sizes.size20),
          shape: Border(
            bottom: BorderSide(
              color: CustomColors.borderDark,
              width: Widths.devider,
            ),
          ),
        ),
        bottomAppBarTheme: BottomAppBarThemeData(
          surfaceTintColor: Colors.transparent,
          color: Colors.transparent,
        ),
        textTheme: textTheme,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: CustomColors.sheetColorDark,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontSize: Sizes.size14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RValues.button),
            side: BorderSide(
              color: CustomColors.borderDark,
              width: Widths.devider,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Paddings.scaffoldV,
          ),
        ),
      ),
    );
  }
}
