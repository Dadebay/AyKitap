# Update reminder after Later

- Removed the persisted skipped-version check from the update sheet.
- Choosing `Soňra` now dismisses the update only for the current app launch.
- If the installed version is still behind the store version, the update sheet is shown again after the app is restarted.
- Added an in-memory launch guard so navigation within one running session cannot stack or repeat the sheet.
