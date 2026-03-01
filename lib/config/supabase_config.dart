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
