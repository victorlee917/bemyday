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
import 'package:bemyday/features/language/language_screen.dart';
import 'package:bemyday/features/navigation/navigation_screen.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/party/party_screen.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/posting/posting_album_screen.dart';
import 'package:bemyday/features/theme/theme_screen.dart';
import 'package:bemyday/features/tutorial/tutorial_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _pendingInviteTokenKey = 'pending_invite_token';

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
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final location = state.matchedLocation;

      // 로그아웃 상태
      if (session == null) {
        final isPublicRoute = location == StartScreen.routeUrl ||
            location == TutorialScreen.routeUrl;
        if (!isPublicRoute) {
          // /invite/:token → 로그인 먼저. 토큰 저장 후 /start로
          final match = RegExp(r'/invite/([^/?#]+)').firstMatch(location);
          if (match != null) {
            final token = match.group(1)!;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_pendingInviteTokenKey, token);
            return '${StartScreen.routeUrl}?invite_token=$token';
          }
          return StartScreen.routeUrl;
        }
        return null;
      }

      // 로그인 상태: 대기 중인 초대 토큰이 있으면 InvitationScreen으로
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_pendingInviteTokenKey);
      if (pendingToken != null) {
        await prefs.remove(_pendingInviteTokenKey);
        return '/invite/$pendingToken';
      }
      final inviteToken = state.uri.queryParameters['invite_token'];
      if (inviteToken != null && location.startsWith(StartScreen.routeUrl)) {
        return '/invite/$inviteToken';
      }

      // 로그인 상태: 프로필 닉네임 확인 (currentProfileProvider 캐시 활용)
      try {
        Profile? profile;
        try {
          profile = await ProviderScope.containerOf(context)
              .read(currentProfileProvider.future);
        } on StateError {
          // ProviderScope 미사용 시 Repository로 조회 (테스트 등)
          profile = await ProfileRepository().getProfile();
        }
        final nickname = profile?.nickname ?? '';
        // 트리거가 부여한 본인 전용 기본값과 비교 (user_ + uuid 앞 8자)
        // 형식만 보면 user_xxx 형태를 유저가 선택할 수 있으므로, 실제 기본값과 일치할 때만 ProfileScreen 유도
        final defaultNickname =
            'user_${session.user.id.replaceAll('-', '').substring(0, 8)}';
        final isDefaultNickname = nickname.isEmpty || nickname == defaultNickname;

        if (isDefaultNickname) {
          if (location.startsWith(ProfileScreen.routeUrl)) return null;
          // 최초 가입 플로우: 닉네임 설정 후 /home으로 이동
          return '${ProfileScreen.routeUrl}?from=onboarding';
        }
        // 커스텀 닉네임: /start, /tutorial에 있으면 /home으로
        if (location == StartScreen.routeUrl || location == TutorialScreen.routeUrl) {
          return '/home';
        }
      } catch (_) {
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
        return fadeOutTransitionPage(child: StartScreen());
      },
    ),
    GoRoute(
      path: ProfileScreen.routeUrl,
      name: ProfileScreen.routeName,
      builder: (context, state) {
        final from = state.uri.queryParameters['from'];
        final initialProfile =
            state.extra is Profile ? state.extra as Profile : null;
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
        return NavigationScreen(tab: tab);
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
    // 딥링크: https://bemyday.app/invite/:token → 초대 받은 사람용
    GoRoute(
      path: '${InviteScreen.routeUrl}/:token',
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
        return slideUpTransitionPage(
          child: PartyDetailScreen(group: group),
        );
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
      builder: (context, state) => PostScreen(),
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
      path: PostingAlbumScreen.routeUrl,
      name: PostingAlbumScreen.routeName,
      pageBuilder: (context, state) {
        final selectedWeekdayIndex = state.extra as int?;
        return slideUpTransitionPage(
          child: PostingAlbumScreen(selectedWeekdayIndex: selectedWeekdayIndex),
        );
      },
    ),
  ],
  );
}
