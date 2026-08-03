# Accept-Language header on every API request

**Date**: 2026-08-03
**Files**: `lib/core/network/dio_client.dart`

## What changed

Every API call now sends `Accept-Language` matching the in-app language:
`tk` (Türkmen), `tr` (Türkçe), `ru` (Русский).

Added to the existing request interceptor in `DioClient`, alongside the bearer
token. `AppLanguageCode` enum names are already exactly `tk`/`ru`/`tr`, so the
header value is `AppLocale.instance.current.name` with no mapping table.

## Why there

- `DioClient.instance` is the only `Dio` in the app (verified: no other `Dio(`
  construction, no `package:http` usage), so one interceptor covers all
  services — collections, books, authors, genres, banners, everything.
- Read **per request**, not once at `BaseOptions` build time, so a language
  switch applies to the very next call without rebuilding the client.
- `AppLocale.instance.load()` runs in `main()` before `runApp`, so no request
  can go out with the default `tk` before the saved language is restored.

## Home refetch on language switch

**File**: `lib/core/services/home_data_service.dart`

The header alone isn't enough for already-loaded screens: switching language
rebuilds `MaterialApp`, but a screen that fetched in `initState` keeps its
State and its old-language data. `HomeDataService` now listens to `AppLocale`
and calls its existing `reload()`, so collection headers and book titles come
back in the new language.

The listener lives in the service, not `HomeScreen`, because:
- the language switch is in Settings, on another tab — Home is off-screen when
  it happens, so a `HomeScreen`-side listener would need Home mounted;
- `BannerCarousel` watches the same service and gets refreshed by the same pass.

Added a `_generation` counter guarding the race where the language changes
while the splash prefetch is still in flight (reachable from the onboarding
language-select screen). Previously `reload()` would null the lists and then
`load()` would bail on the `_loading` guard, leaving Home on its shimmer
forever; and the in-flight response would have written old-language data over
the new. Now `reload()` bumps the generation and takes ownership of
`_loading`, the superseded `load()` returns without notifying, and stale
responses are discarded instead of assigned.

Ordering checked: `HomeDataService.instance` is first constructed in the
`MultiProvider` list (`main.dart:69`), after `AppLocale.instance.load()`
(`main.dart:42`), so startup's `notifyListeners` can't fire a spurious
refetch. `AppLocale.setLanguage` early-returns on an unchanged value, so
re-picking the current language doesn't refetch either.

## Still stale elsewhere

Search, filter, and author/book-detail screens have the same pattern — their
data stays in the previous language until re-entered or refreshed. Not
addressed here.
