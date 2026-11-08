# Offline library check

- When `Connectivity().checkConnectivity()` reports no connection, `SplashScreen` routes to `OfflineLibraryScreen`.
- The normal `LibraryScreen` ("Kitaplygym") is not opened in this state.
- `OfflineLibraryScreen` loads `OwnBooksStore` and shows only locally imported PDF, EPUB, and CBZ files.
- Downloaded catalogue books are not included in this offline screen, even though the normal library has a local `DownloadedTab`.
- Static analysis of the related files completed without errors; only existing style/performance infos were reported.
