# Be My Day Website

Remix 기반 웹사이트 (bemyday.app)

## 페이지

- `/` - 앱 소개 (메인)
- `/invite/:token` - 초대 페이지
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
- `public/.well-known/assetlinks.json` - Android

배포 전 `TEAM_ID`, `sha256_cert_fingerprints`를 실제 값으로 교체하세요.
