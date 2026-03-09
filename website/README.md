# Be My Day Website

Remix 기반 웹사이트 (bemyday.app)

## 페이지

- `/` - 앱 소개 (메인)
- `/invitation/:token` - 초대 페이지
- `/privacy` - 개인정보처리방침
- `/terms` - 서비스이용약관

## 개발

```bash
npm install
npm run dev
```

## 환경 변수

초대 페이지에서 Supabase RPC 호출 시 필요:

- `SUPABASE_URL` - Supabase 프로젝트 URL
- `SUPABASE_ANON_KEY` - Supabase Anon Key

Vercel 배포 시 Project Settings → Environment Variables에 설정.

## 딥링크 설정

- `public/.well-known/apple-app-site-association` - iOS
  - `TEAM_ID`를 Apple Developer Team ID로 교체 (예: `ABCD1234.com.example.bemyday`)
- `public/.well-known/assetlinks.json` - Android
  - `REPLACE_WITH_SHA256_FINGERPRINT`를 앱 서명 SHA256으로 교체
  - 디버그: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`
  - 릴리즈: 앱 서명 키스토어의 SHA256
