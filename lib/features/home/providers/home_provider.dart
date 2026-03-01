import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home 화면에서 현재 선택된 요일 index (0=월 ~ 6=일)
///
/// HomeScreen의 PageView 변경 시 업데이트. NavigationScreen에서 + 버튼 탭 시 참조.
final homeWeekdayIndexProvider = StateProvider<int>((ref) => 0);
