import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_client.dart';

/// What happened to one [AppActivityApiService.report] call — all the caller
/// needs is whether those seconds are still safe to send again.
///
/// This is why app-activity doesn't use [ApiException] like every other
/// service here: the backend keeps no de-duplication for this endpoint, so
/// "the request failed" isn't a single case. Seconds that never left the
/// device must be kept; seconds whose fate is unknown must be dropped, or a
/// retry would count them twice.
enum AppActivityDelivery {
  /// Counted server-side.
  delivered,

  /// The request never reached the server (no connection). The seconds are
  /// still ours — the next report carries them.
  notDelivered,

  /// The request went out but the answer didn't come back, or the server
  /// rejected it. It may or may not have been counted, so per the contract
  /// these seconds are dropped rather than repeated.
  unknown,
}

/// `POST /users/app-activity` — see [ApiEndpoints.appActivity].
class AppActivityApiService {
  AppActivityApiService._();

  static Future<AppActivityDelivery> report({required int seconds}) async {
    try {
      await DioClient.instance.post(ApiEndpoints.appActivity, data: {'seconds': seconds});
      return AppActivityDelivery.delivered;
    } on DioException catch (e) {
      switch (e.type) {
        // Nothing was sent — DNS failure, airplane mode, unreachable host.
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return AppActivityDelivery.notDelivered;
        default:
          return AppActivityDelivery.unknown;
      }
    } catch (_) {
      return AppActivityDelivery.unknown;
    }
  }
}
