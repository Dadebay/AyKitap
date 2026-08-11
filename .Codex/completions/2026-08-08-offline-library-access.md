# Offline library access

- Added a **Kitaplığıma git** action below the connectivity-check action on the offline screen.
- The shortcut opens the normal Library shell on the **İndirilenler** tab, so locally downloaded catalogue books are reachable without a network connection.
- Downloaded files can open offline when the book was purchased, or when the last server-confirmed subscription is still active.
- Subscription expiry is now cached per signed-in user and cleared on logout/account deletion. An expired or absent subscription does not unlock subscription-only downloads; purchased books remain readable.
- `flutter analyze` completed with no errors. Existing informational lint messages remain.
