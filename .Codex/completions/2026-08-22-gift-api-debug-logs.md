# Gift API Debug Logs

- Confirmed the recipient lookup calls `GET /users/is-user-exists` with the
  recipient phone in the query string.
- Confirmed the transfer calls `POST /users/send-to-friend` with numeric
  `phone` and `amount` payload values.
- Added debug-only gift-flow logs for lookup and transfer requests, outcomes,
  and API failures. Phone values are masked in the dedicated logs.
- Corrected response parsing so a top-level `{ "exists": false }` response
  is not mistakenly accepted as a registered user.
