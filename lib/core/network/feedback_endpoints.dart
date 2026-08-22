/// Book-request/problem-report endpoints — [FeedbackApiService]. Split out
/// of the former single `api_endpoints.dart` by which service owns each
/// route. Paths are relative to [ApiConfig.baseUrl].
class FeedbackEndpoints {
  FeedbackEndpoints._();

  /// POST — a "kitap haýyşy" (book request/suggestion).
  static const String suggests = '/suggests';

  /// GET — the signed-in user's own book requests, with review status.
  static const String suggestsMy = '/suggests/my';

  /// DELETE — removes one of the signed-in user's own book requests.
  static String suggestById(int id) => '/suggests/$id';

  /// POST — a free-text bug/problem report.
  static const String problems = '/problems';
}
