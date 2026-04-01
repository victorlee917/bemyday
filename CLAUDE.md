# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Be My Day** (`bemyday`) — A Flutter social app where friend groups share daily photo posts organized by weekday. Backend is Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions) with Firebase for push notifications.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug)
flutter run

# Run with production Supabase config
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Generate localization files (required after changing ARB files)
flutter gen-l10n

# Patch generated l10n (replaces FlutterError with Exception)
./scripts/patch_l10n.sh

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Bump build number before store upload
./scripts/bump_version.sh
```

## Architecture

### State Management: Riverpod + MVVM

- **Riverpod** is the DI and state management framework throughout the app
- Some features use a full **MVVM** pattern with `Notifier`-based ViewModels (e.g., theme, language)
- Others use `FutureProvider`/`StateProvider` directly without a separate ViewModel
- `SharedPreferences` is injected via `ProviderScope` override in `main.dart`
- Auth state tracked via `StreamProvider` wrapping Supabase auth changes

### Feature-First Organization (`lib/features/`)

Each feature follows this internal structure (not all subdirectories required):

```
feature_name/
├── models/          # Plain Dart classes with fromJson factories (no codegen)
├── repositories/    # Supabase client calls (DB, Storage, RPC)
├── providers/       # Riverpod providers
├── viewmodels/      # Notifier subclasses (when MVVM is used)
├── widgets/         # Feature-specific UI components
└── *_screen.dart    # Screen entry point
```

19 features: alarm, auth, comments, friends, group, home, invite, language, license, my, navigation, party, post, posting, profile, push, start, theme, tutorial.

### Key Shared Code

- `lib/core/providers.dart` — `sharedPreferencesProvider`, `authStateProvider`
- `lib/common/widgets/` — Reusable widgets (avatars, sheets, dialogs, async_value_builder)
- `lib/constants/` — sizes, gaps, styles, breakpoints, transitions
- `lib/utils.dart` — `isDarkMode()`, `formatTimeAgo()`, `formatCountdown()`, `showAppSnackBar()`
- `lib/config/supabase_config.dart` — Supabase URL/key with `--dart-define` override support
- `lib/router.dart` — GoRouter with auth-aware redirects and deep link handling

### Data Flow Pattern

```
UI Widget → watches Riverpod Provider → reads Repository → calls Supabase client
```

Repositories are stateless; providers handle caching via Riverpod's `autoDispose`/`keepAlive`. Realtime updates (`lib/features/home/providers/realtime_provider.dart`) subscribe to Supabase channels and invalidate relevant providers on changes.

### Routing

GoRouter with `AuthStateNotifier` for auth-based redirects. Deep links handle invitation tokens via `https://bemyday.app/invitation/:token` and custom scheme `com.bemyday://invitation/:token`.

## Supabase Backend

### Edge Functions (`supabase/functions/`)

- **send-push** — Processes `notification_queue` table, sends FCM push via Google Auth. Cron: every minute.
- **weekday-unlock** — Enqueues weekday unlock notifications when a group's weekday arrives at 00:00 in the group timezone. Cron: every 5 minutes.
- **delete-user-account** — Cleans up user data, deletes avatar storage, soft-deletes auth user.

### Database Conventions

- RLS enabled on all tables
- Soft deletes via `deleted_at` timestamp (posts, comments)
- `SECURITY DEFINER` functions for privileged operations (member counts, group joining, leaving)
- Notification triggers on posts/comments/likes insert into `notification_queue`
- `pg_cron` for scheduled jobs (push sending, weekday unlock)
- Key RPCs: `get_user_groups`, `compute_group_streak`, `leave_group`, `join_group_by_invite_token`, `ensure_profile`, `enqueue_weekday_unlock_notifications`

### Migrations

43 migration files in `supabase/migrations/`. Apply via Supabase MCP or CLI.

## Localization

- ARB files in `lib/l10n/` (template: `app_en.arb`)
- Generated output: `lib/generated/l10n/app_localizations.dart`
- After `flutter gen-l10n`, run `./scripts/patch_l10n.sh` to fix error types
- VS Code pre-launch task runs `patch_l10n.sh` automatically

## Auth Providers

Apple Sign In, Google Sign In, Kakao Login — configured via Supabase Auth with OAuth callbacks routed through GoRouter.

## Firebase Setup

Firebase is used only for FCM push notifications. Config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are gitignored and generated via `flutterfire configure`.
