import 'package:dio/dio.dart';
import '../models/author_detail.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /authors/:id` — the single call behind
/// [CatalogAuthorDetailScreen].
class AuthorApiService {
  AuthorApiService._();

  static Future<AuthorDetail> getAuthorById(int id) async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.authorById(id));
      return AuthorDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
