import 'package:dio/dio.dart';
import '../models/book_suggestion.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the `/suggests` and `/problems` endpoints — [BookRequestSheet]'s
/// book requests and [ReportProblemSheet]'s bug reports. Both are simple
/// "user sends free text, backend logs it against the signed-in account"
/// flows with no response payload the app needs back, unlike the auth
/// endpoints in [AuthApiService].
class FeedbackApiService {
  FeedbackApiService._();

  /// TZ 8.5 — "Kitap haýyşy". [language] is the book's language, not the
  /// app's UI language.
  static Future<void> createBookSuggestion({
    required String name,
    required String author,
    String? description,
    required String language,
  }) async {
    try {
      await DioClient.instance.post(ApiEndpoints.suggests, data: {
        'name': name,
        'author': author,
        if (description != null && description.isNotEmpty)
          'description': description,
        'language': language,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The signed-in user's own book requests, newest first — [name],
  /// [status] (`new`/`accepted`/`rejected`/...) per request.
  static Future<List<BookSuggestion>> getMySuggestions() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.suggestsMy);
      final list = response.data['data'] as List;
      return list
          .map((e) => BookSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Deletes one of the signed-in user's own book requests.
  static Future<void> deleteBookSuggestion(int id) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.suggestById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<void> reportProblem({required String problem}) async {
    try {
      await DioClient.instance
          .post(ApiEndpoints.problems, data: {'problem': problem});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
