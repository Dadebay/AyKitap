/// The one place the backend's origin lives — every request goes through
/// [DioClient], which reads [baseUrl] once at construction, so switching
/// environments never means hunting for a hardcoded host in a call site.
class ApiConfig {
  ApiConfig._();
  // static const String baseUrl = 'http://127.0.0.1:4000/api/v1';
  // static const String fallbackBaseUrl = 'http://127.0.0.1:4000/api/v1';

  static const String baseUrl = 'https://aykitap.com.tm/api/v1';

  /// Optional build-time fallback for networks where the primary domain does
  /// not resolve. The private endpoint stays out of source control.
  static const String fallbackBaseUrl =
      String.fromEnvironment('API_FALLBACK_BASE_URL');

  static bool get hasFallbackBaseUrl => fallbackBaseUrl.isNotEmpty;

  /// Uploaded files (`/public/...` paths from `/users/me`'s `image`,
  /// `/banners`'s `mobile_image`/`website_image`, ...) are proxied by nginx
  /// on this same domain — confirmed serving the real MinIO-backed file
  /// (matching `ETag`) on 443 with no port needed. `:9000` (the media
  /// server's own port) has no TLS listener at all over https.
  static const String mediaBaseUrl = 'https://aykitap.com.tm';

  /// Backend responses return either an already-absolute URL or a bare
  /// storage path on [mediaBaseUrl] — this makes call sites safe to hand
  /// either straight to [Image.network] without checking which.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$mediaBaseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
