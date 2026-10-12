# Subscription pricing toggle

- Subscription routing now uses `iosStoreIapOnlyEnabled` independently of the user's login provider or billing region.
- When enabled, subscription entry points open the RevenueCat/store screen and display the store-localized price (for example USD `$`).
- When disabled, subscription entry points open the wallet tariff screen and display TMT/manat prices, including for Gmail/foreign accounts.
- The Settings subscription entry now uses the same shared routing path as the rest of the app.
- No backend changes were made.
- Focused service tests pass and targeted Flutter analysis reports no issues.
