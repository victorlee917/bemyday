import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SharedPreferences Provider
///
/// main.dart에서 override하여 주입 필요.
/// Theme, Language 등 여러 feature에서 사용.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// 인증 상태 변경 감지. 로그아웃/계정 전환 시 유저별 캐시 무효화용.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
