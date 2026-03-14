# Localization (l10n)

앱 다국어 지원을 위한 번역 파일입니다.

## 구조

- `app_en.arb` - 영어 (기본 템플릿)
- `lib/generated/l10n/` - `flutter gen-l10n`으로 생성되는 Dart 코드

## 새 언어 추가 방법

1. `lib/l10n/`에 `app_XX.arb` 파일 생성 (예: `app_ko.arb`)
2. `app_en.arb`의 모든 키를 복사하고 번역
3. `flutter gen-l10n` 실행
4. `AppLocalizations.supportedLocales`에 새 Locale 추가 (생성된 코드에 자동 반영됨)

## 사용 예시

```dart
import 'package:bemyday/generated/l10n/app_localizations.dart';

// 위젯 내에서
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);
Text(l10n.signUpTitle('Be My Day'));
```

## 참고

- ARB 파일 수정 후 `flutter gen-l10n` 또는 `flutter pub get` 실행 필요
- `l10n.yaml`에서 출력 경로, 클래스명 등 설정 가능
