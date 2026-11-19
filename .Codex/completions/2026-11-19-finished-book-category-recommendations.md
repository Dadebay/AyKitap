# Category-based next-book offer

## Changes

- Replaced the finished-reader offer's Home-collection/author scoring with a lookup of the finished book's actual genres and a `GET /books/all?genre_id=` query.
- Sends `language_id` with the category query when the book-detail response supplies one.
- Excludes the finished book, completed books, matching titles, and books by the same author (including matching author names with different IDs), so alternate-language editions of the just-finished title are not offered.
- Tries another genre if the first has no distinct candidate. If no verified category candidate is available or the network fails, the optional offer stays hidden.
- Kept the offer text-only to avoid decoding another cover while a reader is open.

## Verification

- Recommendation and genre/language request tests passed (8 tests).
- Reader test suite plus the recommendation and genre tests passed before the final request-parameter assertion was added (122 tests); the focused tests were rerun afterward.
- Targeted Flutter analysis returned no errors or warnings; only the existing `flutter/material.dart` deprecation info for the offer widget.
- Live API schema inspection was unavailable because the public endpoint failed TLS from this environment. No Android device is currently attached for a visual check.
