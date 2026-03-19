#!/bin/bash
# Play Store/App Store 업로드 전 버전 코드(build number) 자동 증가
# 사용: ./scripts/bump_version.sh

set -e
PUBSPEC="pubspec.yaml"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "Error: $PUBSPEC not found"
  exit 1
fi

# version: 1.0.1+5 형식에서 + 뒤 숫자 추출
CURRENT=$(grep -E '^version:' "$PUBSPEC" | sed -E 's/.*\+([0-9]+).*/\1/')
NEXT=$((CURRENT + 1))

# version: 1.0.1+X → 1.0.1+Y 로 교체
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version: \([0-9.]*\)+[0-9]*/version: \1+$NEXT/" "$PUBSPEC"
else
  sed -i "s/^version: \([0-9.]*\)+[0-9]*/version: \1+$NEXT/" "$PUBSPEC"
fi

echo "Version bumped: $CURRENT → $NEXT"
grep '^version:' "$PUBSPEC"
