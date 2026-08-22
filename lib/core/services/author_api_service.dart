import 'package:dio/dio.dart';
import '../models/author_detail.dart';
import '../network/catalog_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /authors/:id` — the single call behind
/// [CatalogAuthorDetailScreen].
class AuthorApiService {
  AuthorApiService._();

  static Future<AuthorDetail> getAuthorById(int id) async {
    try {
      final response =
          await DioClient.instance.get(CatalogEndpoints.authorById(id));
      return AuthorDetail.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET `/authors/search?search=` — [SearchScreen]'s "Ýazar" mode.
  static Future<List<AuthorSearchResult>> searchAuthors({
    required String search,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await DioClient.instance
          .get(CatalogEndpoints.authorsSearch, queryParameters: {
        'search': search,
        'page': page,
        'size': size,
      });
      final list = response.data['data'] as List;
      return list
          .map((e) => AuthorSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
