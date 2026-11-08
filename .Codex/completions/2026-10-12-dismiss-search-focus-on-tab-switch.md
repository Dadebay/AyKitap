# Bottom navigation focus dismissal

- Bottom navigation now clears the active text-field focus before switching tabs.
- This prevents the Search keyboard from remaining visible over other pages.
- Both direct tab taps and wheel-driven tab changes use the same guarded path.

## Verification

- `flutter analyze lib/modules/main_nav/main_nav_screen.dart`
- `git diff --check`
