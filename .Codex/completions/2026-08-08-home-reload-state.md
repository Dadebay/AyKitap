# Home reload state

- Home now detects when the collections and banners requests both settle without content, including after a connection interruption.
- Instead of leaving the tab empty, it displays a connection-recovery card with a **Yenile** action.
- The action reloads both Home data sources and restores the normal sections as soon as content arrives.
- `flutter analyze` completed with no errors; one existing import-order informational lint remains.
