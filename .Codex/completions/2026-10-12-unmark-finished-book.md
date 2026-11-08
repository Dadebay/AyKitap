# Persist unmarking a finished book

- Connected both directions of the book-detail finished toggle to the API.
- Marking finished sends 100% progress; removing from Finished deletes the progress record.
- Removed the matching local reading-shelf shadow so stale cache data cannot restore the book.
- Added rollback and an error message when synchronization fails.
- Added focused request-level regression tests for both toggle directions.
