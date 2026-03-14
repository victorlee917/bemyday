# bemyday

A new Flutter project.

## Development Setup

### 1. Firebase 설정

Firebase(FCM 푸시 알림 등)를 사용하므로, 클론 후 한 번 실행해야 합니다:

```bash
# Firebase CLI 설치 (없다면)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 루트에서 실행 → google-services.json, GoogleService-Info.plist, firebase_options.dart 생성
flutterfire configure
```

Firebase 프로젝트 접근 권한이 있는 계정으로 로그인해야 합니다.

**GitHub 푸시 전:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`는 `.gitignore`에 포함되어 있어 커밋되지 않습니다. 이전에 커밋된 적이 있다면 `git rm --cached android/app/google-services.json ios/Runner/GoogleService-Info.plist lib/firebase_options.dart`로 추적 해제 후 커밋하세요.

### 2. Supabase

Debug 모드에서는 `lib/config/supabase_config.dart`의 기본값이 사용됩니다. Release 빌드 시에는 `--dart-define`으로 주입하는 것을 권장합니다.

### 3. 실행

```bash
flutter pub get
flutter run
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
