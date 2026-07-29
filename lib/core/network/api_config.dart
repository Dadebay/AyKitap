/// The one place the backend's origin lives — every request goes through
/// [DioClient], which reads [baseUrl] once at construction, so switching
/// environments never means hunting for a hardcoded host in a call site.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = '<PRIVATE_API_ENDPOINT>';

  /// Uploaded files (`/public/...` paths from `/users/me`'s `image`,
  /// `/banners`'s `mobile_image`/`website_image`, ...) are served by a
  /// separate media host on port 9000 — the API itself stays on 4000.
  static const String mediaBaseUrl = '<PRIVATE_MEDIA_ENDPOINT>';

  /// Backend responses return either an already-absolute URL or a bare
  /// storage path on [mediaBaseUrl] — this makes call sites safe to hand
  /// either straight to [Image.network] without checking which.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$mediaBaseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
