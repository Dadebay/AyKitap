import 'package:dio/dio.dart';
import '../models/genre.dart';
import '../network/catalog_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /genres/all` — the single call behind Search's genre chip
/// row.
class GenreApiService {
  GenreApiService._();

  /// [parentId] narrows to one genre's children; omitted/null fetches the
  /// top-level ones (the backend's own `parent_id: null` rows).
  static Future<List<Genre>> getGenres({int? parentId}) async {
    try {
      final response = await DioClient.instance.get(
        CatalogEndpoints.genresAll,
        queryParameters: {if (parentId != null) 'parent_id': parentId},
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
