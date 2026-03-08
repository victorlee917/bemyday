import 'package:flutter/foundation.dart';

/// Supabase 설정
///
/// - Debug: 기본값 사용 (로컬 개발용)
/// - Release: --dart-define으로 주입 권장
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: kDebugMode ? 'https://qnpikfodyfefbimdbjae.supabase.co' : '',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: kDebugMode
      ? 'sb_publishable_QGJq46caEEDADd9ZhwSmeg_SaT1MxNJ'
      : '',
);

/// Google OAuth Client IDs
///
/// Google Cloud Console → APIs & Services → Credentials 에서 생성.
/// - Web Client ID: Supabase Dashboard의 Google Provider에 설정된 것과 동일해야 함.
/// - iOS Client ID: iOS 앱용 OAuth 2.0 Client ID.
const String googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: kDebugMode
      ? '316354407412-35gk19jhsov02f6rkck49p5kc6s7kqt9.apps.googleusercontent.com'
      : '',
);

const String googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: kDebugMode
      ? '316354407412-3p6arqaebjdv8b3ecm1h9elo05ri85em.apps.googleusercontent.com'
      : '',
);
