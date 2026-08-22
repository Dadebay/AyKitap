# Gift Success Celebration

- Added a localized, non-dismissible gift-success dialog with a one-shot
  `Confetti.json` animation.
- The confirmed transfer now waits for `AccountService.refresh()` before
  displaying success, ensuring the watched profile balance is current when
  the user returns to it.
- Removed the duplicate profile snackbar in favor of the richer success
  dialog.
