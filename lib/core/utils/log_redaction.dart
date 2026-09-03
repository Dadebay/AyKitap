/// Shared secret-masking used by every debug-only logger in the app —
/// [ApiLogInterceptor], and the FCM/APNS token lines in
/// [FirebaseMessagingService] — so a token/secret is masked the same way no
/// matter which log line it came from.
///
/// OneSignal's own diagnostics (`onesignal_client.dart`) already carry an
/// equivalent short-identifier mask predating this file; left as-is rather
/// than migrated, since it was never printing anything in full.
library;

/// Map keys whose value never gets printed in full — matched case- and
/// separator-insensitively (`fcm_token`, `fcmToken` and `FCM-TOKEN` are all
/// the same key to [isSensitiveLogKey]), so a request/response body, a
/// header map or a URL query can all be scrubbed with the same check.
const sensitiveLogKeys = {
  'idtoken',
  'accesstoken',
  'refreshtoken',
  'token',
  'fcmtoken',
  'apnstoken',
  'authorization',
  'password',
  'secret',
  'apikey',
};

bool isSensitiveLogKey(String key) =>
    sensitiveLogKeys.contains(key.toLowerCase().replaceAll(RegExp('[_-]'), ''));

/// Diagnostic-but-safe: enough of the real value survives to tell one
/// token/session apart from another in the log (matching a specific
/// request, or a specific device's token, to a specific failure) without
/// the value itself ever being reconstructable from what's printed.
String maskSecret(String value) {
  if (value.length <= 10) return '***';
  return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
}

/// Recursively rebuilds [value] with every sensitive-keyed entry masked —
/// never mutates its input, always returns a fresh copy safe to log. [key]
/// is the Map key [value] was found under, if any; a List's own elements
/// have no key of their own, so a sensitive key whose value is a List (say
/// `"tokens": [...]`) still masks each element via [key] propagating down
/// into the recursive call.
dynamic redactedForLog(dynamic value, {String? key}) {
  final sensitive = key != null && isSensitiveLogKey(key);
  if (value is Map) {
    return value
        .map((k, v) => MapEntry(k, redactedForLog(v, key: k.toString())));
  }
  if (value is List) {
    return value
        .map((v) => redactedForLog(v, key: sensitive ? key : null))
        .toList();
  }
  if (sensitive) {
    return value is String ? maskSecret(value) : '***';
  }
  return value;
}

/// [uri] with any sensitive query parameter's value(s) masked — built fresh
/// each call, never mutates the [Uri] the real request is sent with.
String redactedUrlForLog(Uri uri) {
  if (uri.query.isEmpty) return uri.toString();
  final redacted = <String, List<String>>{};
  uri.queryParametersAll.forEach((key, values) {
    redacted[key] =
        isSensitiveLogKey(key) ? values.map(maskSecret).toList() : values;
  });
  return uri.replace(queryParameters: redacted).toString();
}
