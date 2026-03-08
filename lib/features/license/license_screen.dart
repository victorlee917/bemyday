import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 패키지명과 라이선스 텍스트
class _LicenseItem {
  const _LicenseItem({required this.packageName, required this.licenseText});

  final String packageName;
  final String licenseText;
}

class _RawEntry {
  const _RawEntry({required this.packages, required this.text});

  final List<String> packages;
  final String text;
}

List<_LicenseItem> _processLicensesIsolate(List<_RawEntry> entries) {
  final byPackage = <String, String>{};
  for (final entry in entries) {
    if (entry.packages.isNotEmpty && entry.text.isNotEmpty) {
      for (final name in entry.packages) {
        byPackage[name] = entry.text;
      }
    }
  }
  final items = byPackage.entries
      .map((e) => _LicenseItem(packageName: e.key, licenseText: e.value))
      .toList();
  items.sort((a, b) => a.packageName.compareTo(b.packageName));
  return items;
}

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  static const routeName = "license";
  static const routeUrl = "/license";

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  List<_LicenseItem>? _licenses;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 렌더 후 로딩 시작 → 네비게이션 전환 완료 후 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLicenses();
    });
  }

  Future<void> _loadLicenses() async {
    final entries = <_RawEntry>[];
    await for (final entry in LicenseRegistry.licenses) {
      entries.add(_RawEntry(
        packages: entry.packages.toList(),
        text: entry.paragraphs
            .map((p) => p.text)
            .where((t) => t.isNotEmpty)
            .join('\n\n'),
      ));
    }
    final items = await _processLicensesInBackground(entries);
    if (mounted) {
      setState(() {
        _licenses = items;
        _loading = false;
      });
    }
  }

  static Future<List<_LicenseItem>> _processLicensesInBackground(
    List<_RawEntry> entries,
  ) {
    return compute(_processLicensesIsolate, entries);
  }

  void _onLicenseTap(_LicenseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LicenseDetailSheet(
        packageName: item.packageName,
        licenseText: item.licenseText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Scaffold(
      appBar: AppBar(title: Text("Open Source License")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _licenses == null || _licenses!.isEmpty
              ? Center(child: Text("No licenses found"))
              : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: Paddings.scaffoldH,
                    right: Paddings.scaffoldH,
                    top: Paddings.scaffoldV,
                    bottom: Paddings.scaffoldV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: Sizes.size20),
                        child: Text(
                          "Packages",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      CustomSizes.sectionTitleGap,
                      Container(
                        decoration: BoxDecoration(
                          color: dark
                              ? CustomColors.clickableAreaDark
                              : CustomColors.clickableAreaLight,
                          borderRadius:
                              BorderRadius.circular(RValues.island),
                          border: Border.all(
                            color: dark
                                ? CustomColors.borderDark
                                : CustomColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _licenses!.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: dark
                                      ? CustomColors.borderDark
                                      : CustomColors.borderLight,
                                ),
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: Paddings.tileH,
                                  vertical: Paddings.tileV,
                                ),
                                minTileHeight: Heights.tileItem,
                                title: Text(
                                  _licenses![i].packageName,
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                trailing: FaIcon(
                                  FontAwesomeIcons.chevronRight,
                                  size: CustomSizes.tileTrailingIcon,
                                ),
                                onTap: () => _onLicenseTap(_licenses![i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _LicenseDetailSheet extends StatelessWidget {
  const _LicenseDetailSheet({
    required this.packageName,
    required this.licenseText,
  });

  final String packageName;
  final String licenseText;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final sheetColor =
        dark ? CustomColors.sheetColorDark : CustomColors.sheetColorLight;
    final borderColor =
        dark ? CustomColors.borderDark : CustomColors.borderLight;
    final fgColor = dark ? Colors.white : Colors.black;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: Scaffold(
        backgroundColor: sheetColor,
        appBar: AppBar(
          title: Text(
            packageName,
            style: TextStyle(fontSize: Sizes.size14, color: fgColor),
            overflow: TextOverflow.ellipsis,
          ),
          automaticallyImplyLeading: false,
          backgroundColor: sheetColor,
          shape: Border(
            bottom: BorderSide(
              color: borderColor,
              width: Widths.devider,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.circleXmark,
                  size: Sizes.size20,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Paddings.scaffoldV,
          ),
          child: SelectableText(
            licenseText,
            style: TextStyle(
              fontSize: Sizes.size12,
              height: 1.5,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }
}
