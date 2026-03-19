#!/bin/bash
# FlutterError → Exception 패치 (gen-l10n 생성 후 실행)
# 사용: ./scripts/patch_l10n.sh
set -e
cd "$(dirname "$0")/.."
flutter pub get
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/throw FlutterError(/throw Exception(/' lib/generated/l10n/app_localizations.dart
else
  sed -i 's/throw FlutterError(/throw Exception(/' lib/generated/l10n/app_localizations.dart
fi
echo "Patched app_localizations.dart"
