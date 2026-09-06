import 'package:dio/dio.dart';
import '../models/author_detail.dart';
import '../network/api_exception.dart';
import '../network/catalog_endpoints.dart';
import '../network/dio_client.dart';

/// Talks to `GET /authors/:id` — the single call behind
/// [CatalogAuthorDetailScreen].
class AuthorApiService {
  AuthorApiService._();

  static Future<AuthorDetail> getAuthorById(int id) async {
    try {
      final response = await DioClient.instance.get(CatalogEndpoints.authorById(id));
      return AuthorDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET `/authors/search?search=` — [SearchScreen]'s "Awtor" mode.
  ///
  /// An empty [search] is also valid — confirmed against the live backend —
  /// and is what powers that mode's own "discover" grid (shown before the
  /// user has typed anything, same idea as the Book mode's discover grid).
  /// [sortBy]/[sortOrder] are sent the same way `/books/all` takes them, but
  /// this endpoint doesn't currently seem to act on them — passed through
  /// anyway so this call is already correct if/when it starts to.
  static Future<List<AuthorSearchResult>> searchAuthors({
    String search = '',
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await DioClient.instance.get(CatalogEndpoints.authorsSearch, queryParameters: {
        'search': search,
        'page': page,
        'size': size,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      });
      final list = response.data['data'] as List;
      return list.map((e) => AuthorSearchResult.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
