# Offline reading direct open

- Tapping a book on the locally cached **Okuduklarım** shelf now checks connectivity first.
- With no connection, the app bypasses `GET /books/:id` and opens the matching app-private downloaded file directly after confirming the local access rule.
- With connectivity, the existing catalogue detail (`GET /books/:id`) behavior remains unchanged.
- A clear message is shown if the book is listed locally but its downloadable file is no longer on the device or access has lapsed.
- `flutter analyze` completed without errors; one existing informational const suggestion remains.
