# Codebase Refactor Audit — 2026-08-08

## Scope

Audited Dart source files for the requested 300-line limit, reusable widgets,
and appropriate Provider migration. After approval, the first low-risk
refactor batch was implemented and statically checked.

## Findings

- 16 application Dart files exceed 300 lines. The largest are the reader
  screens/provider, search, book detail, and settings sheets.
- Provider is already installed and used for application-level services and
  reader state.
- Local `setState` is also used for animation, focus, gestures, controller
  input, and transient sheet state. Those cases should remain local because
  moving them to a global Provider would add broad rebuilds and state lifetime
  complexity without making the data shareable.
- `flutter analyze` completed with no errors. It reported two unused imports
  and lint/style suggestions (131 total issues).

## Proposed implementation phases

1. Extract reusable presentation widgets and split all oversized UI files to
   at most 300 lines without changing behavior.
2. Add feature-scoped ChangeNotifiers for remote/loading/error/selection state
   in Search, Book Detail, Balance, Subscription, and Library.
3. Keep reader gesture/animation/device-control state local initially; only
   extract shared reader controls after regression coverage is added.
4. Apply safe analyzer cleanups and add focused Provider/widget tests.

## Implemented in the first batch

- Extracted `NewBookRequestBar` from `BookSuggestionsScreen`; both files are
  now below the limit.
- Extracted balance history/order tiles and moved balance remote state to the
  feature-scoped `BalanceController` ChangeNotifier. The selected tab remains
  local UI state.
- Added reusable `ReaderFitTile` and replaced duplicated PDF/CBZ settings
  implementations. `CbzSettingsSheet` is now 299 lines.
- Full `flutter analyze` reports no errors; existing lint/style diagnostics
  remain and no test directory is currently present.
