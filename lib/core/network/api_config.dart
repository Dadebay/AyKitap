/// The one place the backend's origin lives — every request goes through
/// [DioClient], which reads [baseUrl] once at construction, so switching
/// environments never means hunting for a hardcoded host in a call site.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://aykitap.com.tm/api/v1';

  /// `aykitap.com.tm` doesn't resolve on every network (seen in practice —
  /// see [payment_api_service.dart]'s `activateOrder` for the same issue
  /// with the `api.` subdomain). [DioClient] retries against this IP-based
  /// host on a connection failure so the app still works there.
  static const String fallbackBaseUrl = '<PRIVATE_API_ENDPOINT>';

  /// Uploaded files (`/public/...` paths from `/users/me`'s `image`,
  /// `/banners`'s `mobile_image`/`website_image`, ...) are served by the
  /// same domain but on a separate port — the domain doesn't proxy this
  /// host without it.
  static const String mediaBaseUrl = 'https://aykitap.com.tm';
  // static const String mediaBaseUrl = '<PRIVATE_MEDIA_ENDPOINT>';

  /// Backend responses return either an already-absolute URL or a bare
  /// storage path on [mediaBaseUrl] — this makes call sites safe to hand
  /// either straight to [Image.network] without checking which.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$mediaBaseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
