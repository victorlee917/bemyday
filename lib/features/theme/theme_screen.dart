import 'package:bemyday/common/widgets/tile/tile_select.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/theme/viewmodels/theme_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [View] 테마 설정 화면
///
/// Riverpod의 ConsumerWidget 사용:
/// - ref.watch로 상태 구독
/// - ref.read로 메서드 호출
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});
  static const routeName = "theme";
  static const routeUrl = "/theme";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // state를 watch해야 변경 시 리빌드됨
    ref.watch(themeViewModelProvider);
    // notifier는 메서드 호출용
    final themeViewModel = ref.read(themeViewModelProvider.notifier);
    final currentThemeMode = themeViewModel.themeModeString;

    // 사용자 이벤트 -> ViewModel에 전달
    void onTileTap(String themeMode) {
      themeViewModel.setThemeMode(themeMode);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Theme")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.only(
            left: Paddings.scaffoldH,
            right: Paddings.scaffoldH,
            top: Paddings.scaffoldV,
          ),
          child: TilesSection(
            items: [
              TileSelect(
                title: "Light",
                option: "light",
                selectedOption: currentThemeMode,
                onTileTap: onTileTap,
              ),
              TileSelect(
                title: "Dark",
                option: "dark",
                selectedOption: currentThemeMode,
                onTileTap: onTileTap,
              ),
              TileSelect(
                title: "Device",
                option: "device",
                selectedOption: currentThemeMode,
                onTileTap: onTileTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
