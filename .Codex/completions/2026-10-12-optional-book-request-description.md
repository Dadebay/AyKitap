# Optional book-request description

- Kept book title and author as the only required fields in the app.
- When the optional description is blank, the app now sends an empty string instead of omitting the API field.
- This satisfies the backend's current non-null database column without requiring a backend change.
- Added a focused API payload regression test.
