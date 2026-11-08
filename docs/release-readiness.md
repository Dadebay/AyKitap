# Release readiness — 2026-11-08

This document tracks checks that cannot be proven by a source build. It is not a claim that the current branch is ready for store rollout.

## Required before a new Android or iOS binary

1. **Review and merge the PR.** The review branch includes the existing reader/tablet work from `feat/reader-ui` as well as the cleanup. Confirm GitHub CI and review comments before merging to `main`.
2. **Verify account deletion.** `SettingsScreen._confirmDeleteAccount` currently calls the same local-session cleanup as logout. The backend owner must provide and document a real account deletion endpoint, including purchased-book and subscription implications. Then implement and test the full in-app flow. Do not describe the current button as server-side deletion.
3. **Reconcile privacy declarations.** The public Google Play listing currently says “No data collected”, while source initializes Firebase Analytics and also includes Firebase Messaging, OneSignal, and RevenueCat. The privacy owner must compare actual SDK behavior, consent, and store disclosures, then update the console declarations and privacy policy where required.
4. **Confirm signing.** `android/key.properties` is absent from this checkout. The release keystore exists in secure local storage, but its alias/password and whether its certificate matches Google Play's app-signing certificate have not been verified. Do not publish a debug or unsigned APK.
5. **Run device checks.** On supported Android and iOS devices, test an upgrade from the current store build, login and logout offline, EPUB/PDF/CBZ open and resume, downloaded books offline, store purchases in the approved test environment, and tablet layouts. Validate backend compatibility and error states.
6. **Confirm distribution version.** Compare `pubspec.yaml` version/build with both stores. Increase Android versionCode and iOS build number for a new store submission. Tag the exact validated commit, then create a GitHub Release with honest notes. Attach a signed Android APK and SHA-256 only after the certificate and device checks pass.

## CI scope

The PR workflow checks formatting, analysis, tests, an Android debug build, and an iOS no-codesign build. Those builds exercise compilation without needing release secrets. They do not validate App Store provisioning, Google Play App Signing, purchase settlement, or backend deletion.
