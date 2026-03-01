import 'package:bemyday/common/widgets/tile/tile_select.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/language/viewmodels/language_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});
  static const routeName = "language";
  static const routeUrl = "/language";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // state를 watch해야 변경 시 리빌드됨
    ref.watch(languageViewModelProvider);
    // notifier는 메서드 호출용
    final languageViewModel = ref.read(languageViewModelProvider.notifier);
    final currentLanguage = languageViewModel.currentLanguage;

    // 사용자 이벤트 -> ViewModel에 전달
    void onTileTap(String language) {
      languageViewModel.setLanguage(language);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Language")),
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
                title: "English",
                option: "en",
                selectedOption: currentLanguage,
                onTileTap: onTileTap,
              ),
              TileSelect(
                title: "Korean",
                option: "ko",
                selectedOption: currentLanguage,
                onTileTap: onTileTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
