import 'package:dio/dio.dart';
import '../models/promo_banner.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET /banners` — the single call behind [BannerCarousel].
class BannerApiService {
  BannerApiService._();

  /// Active banners, ordered for display. The endpoint is documented as
  /// already filtering to active-only, but `is_active`/`order` are filtered
  /// and sorted here too rather than trusting that to hold forever.
  static Future<List<PromoBanner>> getBanners() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.banners);
      final list = response.data['data'] as List;
      final banners = list.map((e) => PromoBanner.fromJson(e as Map<String, dynamic>)).where((b) => b.isActive).toList();
      banners.sort((a, b) => a.order.compareTo(b.order));
      return banners;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
