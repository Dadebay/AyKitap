import 'package:dio/dio.dart';
import '../models/book_language.dart';
import '../network/catalog_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /book-languages` — the single call behind the filter
/// page's "Dil" section.
class BookLanguageApiService {
  BookLanguageApiService._();

  static Future<List<BookLanguage>> getLanguages() async {
    try {
      final response =
          await DioClient.instance.get(CatalogEndpoints.bookLanguages);
      final list = response.data['data'] as List;
      return list
          .map((e) => BookLanguage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
