# Show opened books on the reading shelf

- Fixed the Reading shelf overwriting a freshly opened local book with an empty backend response before the first progress report.
- Reconciled complete backend progress rows with the local reading shadow, retaining unsynced opens and removing completed books.
- Added a live local-store listener so the permanently mounted Library tab updates as soon as a reader opens.
- Added focused store and widget regression coverage.
