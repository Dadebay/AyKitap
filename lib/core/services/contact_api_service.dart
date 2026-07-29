import 'package:dio/dio.dart';
import '../models/contact_info.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /contacts` — the single call behind [ContactUsSheet].
class ContactApiService {
  ContactApiService._();

  static Future<ContactInfo> getContacts() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.contacts);
      return ContactInfo.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
