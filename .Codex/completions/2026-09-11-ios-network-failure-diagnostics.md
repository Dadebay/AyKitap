# Network failures: make them say what happened, and let the fallback host fire

Reported as "on iPhone every API call fails in debug (`unknown — null`) while
Android works fine".

## What the log was actually telling us: nothing

Every failing line read `✕ API GET /api/v1/... unknown — null`, which means
`type == DioExceptionType.unknown`, no response, and a null `message`.

`ApiException._debugLogUnhandled` printed `e.message` and never `e.error` —
and for a transport-level failure `message` is routinely null while `error`
holds the whole story (a `HandshakeException`, a `SocketException` with its OS
error, …). So the one log line covering this case discarded the only field
that said which side to fix.

`ApiException.failureDetail` (new, `@visibleForTesting`) now prefers, in
order: the response body → the underlying exception *with its runtime type* →
`message` → an explicit statement that there was neither. The type matters
because it is what separates causes needing different fixes: a
`HandshakeException` is the platform refusing the TLS connection, a
`SocketException` is the host never resolving.

## Why the fallback host never got a chance

`ApiConfig.fallbackBaseUrl` exists because the primary domain "does not
resolve on every network", and `DioClient`'s error interceptor retries against
it — but only for `connectionError`/`connectionTimeout`.

A TLS connection the platform refuses does not arrive as either. Dio files it
as `unknown` with a null message, which is exactly what the iPhone reported.
So the fallback was skipped for precisely the platform-specific failures it
was added to cover.

`shouldRetryOnFallbackHost` (new, `@visibleForTesting`) replaces the inline
type check and asks the question that actually matters — *did this request
ever reach a server?*: no response, and a connection-level type
(`connectionError`, `connectionTimeout`, or `unknown`). A failure that carried
a response is deliberately excluded: the host answered, so retrying elsewhere
would only hide a request/server problem.

## The platform asymmetry behind "Android works, iOS doesn't"

Verified, and worth recording because it explains the shape of the report:

| | cleartext HTTP |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `android:usesCleartextTraffic="true"` — allowed |
| `ios/Runner/Info.plist` | no `NSAppTransportSecurity` key at all — default ATS, **blocked** |

And per `3be56a3`'s README diff, the endpoint that moved into
`API_FALLBACK_BASE_URL` is a cleartext HTTP origin on a raw IP. The value
itself deliberately stays out of source control — that commit is what took it
out, so it does not get written back here either.

Putting those together, the likely sequence is: the primary
`https://aykitap.com.tm` fails on this network for *both* platforms; Android
falls back to the cleartext IP and looks healthy; iOS both (a) never attempted
the fallback, because of the `unknown` gap fixed above, and (b) would have had
ATS refuse it anyway.

That last point is **not** something to paper over with an ATS exception
without deciding to: the primary HTTPS domain failing is the real defect, and
an `NSAppTransportSecurity` hole to reach a cleartext IP weakens the shipped
app and needs justifying at App Store review. Left alone here on purpose.

## Changed files

- `lib/core/network/api_exception.dart` — `failureDetail`
- `lib/core/network/dio_client.dart` — `shouldRetryOnFallbackHost`
- `test/core/network/network_failure_diagnostics_test.dart` (new, 9 tests)

## Verification

- `flutter test test/core/network/` — 21/21 pass.
- `flutter analyze lib/core/network test/core/network` — clean.
- `flutter test` — 297 pass, 2 fail; both the long-standing
  `settings_screen_revenue_cat_test.dart` failures from the in-progress
  RevenueCat/IAP work.

Network probes from the dev machine were inconclusive and are *not* recorded
as evidence here: DNS lookups time out and connects return in ~2 ms from this
environment, so it cannot see what the phone sees.

## What the improved log then reported

`HandshakeException: Connection terminated during handshake`, on every call.

That is the peer closing the TCP connection *during* the TLS handshake — not
a certificate that failed to verify (which reads `CERTIFICATE_VERIFY_FAILED`)
and not a refused connection. Nothing in the app is involved: a grep confirms
no certificate pinning, no custom `SecurityContext`, no custom
`HttpClientAdapter` anywhere in `lib/`.

**Correction to the ATS note above.** It does not apply to these calls.
Flutter's `dart:io` `HttpClient` — what Dio uses through `IOHttpClientAdapter`
— carries its own BoringSSL and does not go through `NSURLSession`, so App
Transport Security never sees this traffic. The Info.plist/manifest asymmetry
is real but is not what was blocking the API, and the cleartext fallback host
needs no ATS exception to work on iOS. Recorded here rather than deleted
because the wrong conclusion is the instructive part: both platforms run the
*same* Dart TLS stack, which is why a handshake that one accepts and the other
does not points at the network path, not at platform TLS policy.

## Resolution

Confirmed by the reporter: it was TLS on `aykitap.com.tm`, and iOS fetches
data again once that was addressed. The app code was never at fault — which
is exactly what took a session to establish, because the one log line covering
this failure printed `unknown — null` and named neither the cause nor the
origin in play.

Worth keeping in mind now that it works: whether iOS is being served by the
primary HTTPS origin or by the cleartext fallback is not visible from the
screen, only from the new `🌐 API base=… fallback=…` startup line. It matters
because `DioClient` attaches `Authorization: Bearer <token>` to every request,
so a build that quietly rides the fallback sends that token — and `/users/me`
— unencrypted. Fine for local development, not something to ship.

## Next step

Re-run on the iPhone. The same failing calls will now name their cause, e.g.
`✕ API GET /api/v1/collections/all unknown — HandshakeException: ...` (the
platform rejected TLS — a server certificate-chain or ATS matter) versus
`SocketException: Failed host lookup` (the domain does not resolve on that
network, which is the case the fallback host is for).
