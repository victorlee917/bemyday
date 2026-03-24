import 'package:bemyday/constants/transitions.dart';
import 'package:bemyday/features/alarm/alarm_screen.dart';
import 'package:bemyday/features/party/party_detail_screen.dart';
import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/features/profile/profile_screen.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/profile/repositories/profile_repository.dart';
import 'package:bemyday/features/start/start_screen.dart';
import 'package:bemyday/features/invite/invitation_screen.dart';
import 'package:bemyday/features/invite/invite_screen.dart';
import 'package:bemyday/features/invite/repositories/invitation_repository.dart';
import 'package:bemyday/features/language/language_screen.dart';
import 'package:bemyday/features/license/license_screen.dart';
import 'package:bemyday/features/navigation/navigation_screen.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/features/theme/theme_screen.dart';
import 'package:bemyday/features/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SharedPreferences 키. main.dart에서 cold start 시 stale token 제거용으로도 사용.
const pendingInviteTokenKey = 'pending_invite_token';

/// GoRouter의 [refreshListenable]에 사용. 인증 상태 변경 시 redirect 재평가.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

GoRouter createRouter(
  AuthStateNotifier authStateNotifier, {
  String? initialLocation,
}) {
  return GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: initialLocation ?? StartScreen.routeUrl,
    // 플랫폼이 com.bemyday://invitation/xxx 전달 시 initialLocation(변환된 경로) 우선 사용
    overridePlatformDefaultLocation: initialLocation != null,
    onException: (context, state, router) {
      // GoException "no routes for location: ..." → 유효한 경로로 리다이렉트
      final err = state.error;
      if (err is GoException) {
        final msg = err.message;
        // com.bemyday://invitation/TOKEN → /invitation/TOKEN
        final inviteMatch = RegExp(
          r'no routes for location: (com\.bemyday://invitation/[^"\s]+)',
        ).firstMatch(msg);
        if (inviteMatch != null) {
          final uriStr = inviteMatch.group(1)!;
          final tokenMatch = RegExp(
            r'com\.bemyday://invitation/([^/?#]+)',
          ).firstMatch(uriStr);
          if (tokenMatch != null) {
            router.go('/invitation/${tokenMatch.group(1)!}');
            return;
          }
        }
        // com.bemyday://login-callback, com.bemyday:// 등 OAuth 콜백 → /start (redirect에서 /home 등으로 처리)
        final schemeMatch = RegExp(
          r'no routes for location: (com\.bemyday://[^"]*)',
        ).firstMatch(msg);
        if (schemeMatch != null) {
          router.go(StartScreen.routeUrl);
          return;
        }
      }
      // 그 외: 기본 에러 화면 (재throw 없음)
    },
    redirect: (context, state) async {
      // uri.toString()으로 location 확인 (go_router 17: location → uri.toString())
      final location = state.uri.toString();
      final session = Supabase.instance.client.auth.currentSession;

      // com.bemyday://invitation/TOKEN → 로그인 시 바텀시트, 로그아웃 시 /start
      // getInitialLink stale 값 방지: 유효한 초대만 리다이렉트
      final schemeMatch = RegExp(
        r'^com\.bemyday://invitation/([^/?#]+)',
      ).firstMatch(location);
      if (schemeMatch != null) {
        final token = schemeMatch.group(1)!;
        final data = await InvitationRepository().getInvitationByToken(token);
        if (data != null) {
          return session != null
              ? '/home?invitation_token=$token'
              : '${StartScreen.routeUrl}?invite_token=$token';
        }
        return session != null ? '/home' : TutorialScreen.routeUrl;
      }

      // 로그아웃 상태
      if (session == null) {
        final inviteMatch = RegExp(
          r'^/invitation/([^/?#]+)',
        ).firstMatch(location);
        final path = state.uri.path;
        final isPublicRoute =
            path == StartScreen.routeUrl || path == TutorialScreen.routeUrl;
        // /invitation/:token → 로그인 필요하므로 /start?invite_token=TOKEN으로
        if (inviteMatch != null) {
          final token = inviteMatch.group(1)!;
          return '${StartScreen.routeUrl}?invite_token=$token';
        }
        if (!isPublicRoute) {
          final match = RegExp(r'/invitation/([^/?#]+)').firstMatch(location);
          if (match != null) {
            final token = match.group(1)!;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(pendingInviteTokenKey, token);
            return '${StartScreen.routeUrl}?invite_token=$token';
          }
          return TutorialScreen.routeUrl;
        }
        return null;
      }

      // 로그인 상태: 대기 중인 초대 토큰 → /home?invitation_token=TOKEN (바텀시트로 표시)
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(pendingInviteTokenKey);
      if (pendingToken != null) {
        await prefs.remove(pendingInviteTokenKey);
        final data = await InvitationRepository().getInvitationByToken(
          pendingToken,
        );
        if (data != null) return '/home?invitation_token=$pendingToken';
      }
      final inviteToken = state.uri.queryParameters['invite_token'];
      if (inviteToken != null && location.startsWith(StartScreen.routeUrl)) {
        final data = await InvitationRepository().getInvitationByToken(
          inviteToken,
        );
        if (data != null) return '/home?invitation_token=$inviteToken';
      }

      // /invitation/TOKEN 경로로 진입 시 (로그인) → /home?invitation_token=TOKEN (바텀시트)
      final pathInviteMatch = RegExp(
        r'^/invitation/([^/?#]+)',
      ).firstMatch(state.uri.path);
      if (pathInviteMatch != null) {
        final token = pathInviteMatch.group(1)!;
        final data = await InvitationRepository().getInvitationByToken(token);
        if (data != null) return '/home?invitation_token=$token';
        return '/home';
      }

      // 로그인 상태: 프로필 닉네임 확인 (currentProfileProvider 캐시 활용)
      try {
        Profile? profile;
        try {
          profile = await ProviderScope.containerOf(
            context,
          ).read(currentProfileProvider.future);
        } on StateError {
          // ProviderScope 미사용 시 Repository로 조회 (테스트 등)
          profile = await ProfileRepository().getProfile();
        }
        // 프로필 없음: ensure_profile로 생성 시도 (soft delete 후 재가입 등)
        if (profile == null) {
          await ProfileRepository().ensureProfile();
          profile = await ProfileRepository().getProfile();
          if (profile == null) {
            await Supabase.instance.client.auth.signOut();
            return TutorialScreen.routeUrl;
          }
        }
        final nickname = profile.nickname;
        // 트리거가 부여한 본인 전용 기본값과 비교 (user_ + uuid 앞 8자)
        // 형식만 보면 user_xxx 형태를 유저가 선택할 수 있으므로, 실제 기본값과 일치할 때만 ProfileScreen 유도
        final defaultNickname =
            'user_${session.user.id.replaceAll('-', '').substring(0, 8)}';
        final isDefaultNickname =
            nickname.isEmpty || nickname == defaultNickname;

        if (isDefaultNickname) {
          if (location.startsWith(ProfileScreen.routeUrl)) return null;
          // 최초 가입 플로우: 닉네임 설정 후 /home으로 이동
          return '${ProfileScreen.routeUrl}?from=onboarding';
        }
        // 커스텀 닉네임: /start, /tutorial에 있으면 /home으로 (쿼리 파라미터 무시)
        final path = state.uri.path;
        if (path == StartScreen.routeUrl || path == TutorialScreen.routeUrl) {
          return '/home';
        }
      } catch (_) {
        // 프로필 조회 실패 (예외): /tutorial, /start에 있으면 유지, 아니면 ProfileScreen
        final path = state.uri.path;
        if (path == StartScreen.routeUrl || path == TutorialScreen.routeUrl) {
          return null;
        }
        return ProfileScreen.routeUrl;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: TutorialScreen.routeUrl,
        name: TutorialScreen.routeName,
        builder: (context, state) => TutorialScreen(),
      ),
      GoRoute(
        path: StartScreen.routeUrl,
        name: StartScreen.routeName,
        pageBuilder: (context, state) {
          final authError = state.uri.queryParameters['auth_error'];
          final inviteToken = state.uri.queryParameters['invite_token'];
          return fadeOutTransitionPage(
            child: StartScreen(
              authErrorRetry: authError == 'retry',
              inviteToken: inviteToken,
            ),
          );
        },
      ),
      GoRoute(
        path: ProfileScreen.routeUrl,
        name: ProfileScreen.routeName,
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          final initialProfile = state.extra is Profile
              ? state.extra as Profile
              : null;
          return ProfileScreen(
            fromOnboarding: from == 'onboarding',
            initialProfile: initialProfile,
          );
        },
      ),
      GoRoute(
        path: "/:tab(home|friends|my)",
        name: NavigationScreen.routeName,
        builder: (context, state) {
          final tab = state.pathParameters["tab"]!;
          final weekdayParam = state.uri.queryParameters['weekday'];
          final initialWeekdayIndex = weekdayParam != null
              ? int.tryParse(weekdayParam)
              : null;
          final invitationToken = state.uri.queryParameters['invitation_token'];
          return NavigationScreen(
            tab: tab,
            initialWeekdayIndex: initialWeekdayIndex,
            invitationToken: invitationToken,
          );
        },
      ),
      GoRoute(
        path: InviteScreen.routeUrl,
        name: InviteScreen.routeName,
        pageBuilder: (context, state) {
          final selectedWeekdayIndex = state.extra as int?;
          return slideUpTransitionPage(
            child: InviteScreen(selectedWeekdayIndex: selectedWeekdayIndex),
          );
        },
      ),
      // 딥링크: https://bemyday.app/invitation/:token → 초대 받은 사람용
      GoRoute(
        path: '${InvitationScreen.routeUrl}/:token',
        name: InvitationScreen.routeName,
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return slideUpTransitionPage(
            child: InvitationScreen(inviteToken: token),
          );
        },
      ),
      GoRoute(
        path: PartyScreen.routeUrl,
        name: PartyScreen.routeName,
        pageBuilder: (context, state) {
          final group = state.extra as Group?;
          return slideUpTransitionPage(child: PartyScreen(group: group));
        },
      ),
      GoRoute(
        path: PartyDetailScreen.routeUrl,
        name: PartyDetailScreen.routeName,
        pageBuilder: (context, state) {
          final group = state.extra as Group?;
          return slideUpTransitionPage(child: PartyDetailScreen(group: group));
        },
      ),
      GoRoute(
        path: AlarmScreen.routeUrl,
        name: AlarmScreen.routeName,
        builder: (context, state) => AlarmScreen(),
      ),
      GoRoute(
        path: PostScreen.routeUrl,
        name: PostScreen.routeName,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final Widget child;
          if (extra is Map) {
            child = PostScreen(
              group: extra['group'] as Group?,
              weekIndex: extra['weekIndex'] as int?,
              startFromLatest: extra['startFromLatest'] as bool? ?? false,
              focusPostId: extra['focusPostId'] as String?,
            );
          } else {
            child = PostScreen(group: extra as Group?);
          }
          return slideUpTransitionPage(child: child, opaque: false);
        },
      ),
      GoRoute(
        path: ThemeScreen.routeUrl,
        name: ThemeScreen.routeName,
        builder: (context, state) => ThemeScreen(),
      ),
      GoRoute(
        path: LanguageScreen.routeUrl,
        name: LanguageScreen.routeName,
        builder: (context, state) => LanguageScreen(),
      ),
      GoRoute(
        path: LicenseScreen.routeUrl,
        name: LicenseScreen.routeName,
        builder: (context, state) => LicenseScreen(),
      ),
      GoRoute(
        path: PostingAlbumScreen.routeUrl,
        name: PostingAlbumScreen.routeName,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final int? selectedWeekdayIndex =
              extra is Map ? extra['selectedWeekdayIndex'] as int? : extra as int?;
          final bool replaceOnPostSuccess =
              extra is Map ? (extra['replaceOnPostSuccess'] as bool? ?? false) : false;
          final int? postScreenWeekIndex =
              extra is Map ? extra['postScreenWeekIndex'] as int? : null;
          return slideUpTransitionPage(
            child: PostingAlbumScreen(
              selectedWeekdayIndex: selectedWeekdayIndex,
              replaceOnPostSuccess: replaceOnPostSuccess,
              postScreenWeekIndex: postScreenWeekIndex,
            ),
          );
        },
      ),
    ],
  );
}
