# Offline reading network fallback

- A Wi-Fi/mobile interface reported by the OS is no longer treated as proof that `GET /books/:id` can actually reach the backend.
- For a cached **Okuduklarım** book, a failed detail request now falls back to the app-private downloaded file and opens the reader.
- A working online request still displays the normal catalogue detail screen.
- `flutter analyze` completed with no errors; only two existing informational style suggestions remain.
