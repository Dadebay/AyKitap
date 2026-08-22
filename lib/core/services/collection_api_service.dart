import 'package:dio/dio.dart';
import '../models/collection.dart';
import '../network/catalog_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /collections/all` — the single call behind Home's stacked
/// collection sections ([HomeScreen]).
class CollectionApiService {
  CollectionApiService._();

  static Future<List<Collection>> getCollections() async {
    try {
      final response =
          await DioClient.instance.get(CatalogEndpoints.collectionsAll);
      final list = response.data['data'] as List;
      return list
          .map((e) => Collection.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
