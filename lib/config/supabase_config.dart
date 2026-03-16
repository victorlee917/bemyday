/// Supabase 설정
///
/// - --dart-define으로 오버라이드 가능:
///   flutter build ipa --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// - 기본값: Debug/Release 공통 (TestFlight 등 프로덕션 빌드에서도 동작)
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://qnpikfodyfefbimdbjae.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_QGJq46caEEDADd9ZhwSmeg_SaT1MxNJ',
);

/// Google OAuth Client IDs
///
/// Google Cloud Console → APIs & Services → Credentials 에서 생성.
/// - Web Client ID: Supabase Dashboard의 Google Provider에 설정된 것과 동일해야 함.
/// - iOS Client ID: iOS 앱용 OAuth 2.0 Client ID.
const String googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '316354407412-35gk19jhsov02f6rkck49p5kc6s7kqt9.apps.googleusercontent.com',
);

const String googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '316354407412-3p6arqaebjdv8b3ecm1h9elo05ri85em.apps.googleusercontent.com',
);

/// Kakao Native App Key (카카오톡 앱 로그인용)
///
/// Kakao Developers → 앱 설정 → 플랫폼 → Android/iOS → 네이티브 앱 키
/// Supabase Kakao Provider에 Native App Key 사용 시 id_token 검증 가능
const String kakaoNativeAppKey = String.fromEnvironment(
  'KAKAO_NATIVE_APP_KEY',
  defaultValue: '47f557a206cff530114f3a03bbb9de66',
);
