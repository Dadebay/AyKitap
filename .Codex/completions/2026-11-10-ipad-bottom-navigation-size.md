# iPad bottom navigation size

- Enlarged only the full-size iPad wheel: 88-point selected button, 60-point other icon wells, larger glyphs and 72-point hit targets.
- Increased iPad wheel height and icon spacing, and aligned its visible window with the five navigation tabs.
- Updated wheel drag distance and `WheelNavBar.clearance` to use the same iPad geometry. Phone and Android tablet dimensions remain unchanged.
- Verified with targeted `flutter analyze` (no errors in changed files; one existing import-order info in `offline_library_screen.dart`) and `git diff --check`.
- Visual device test left to the user as requested.
