import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/account_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the `/users/*` gift-sending endpoints — [SendGiftSheet]'s "send
/// balance to another registered user" flow. [checkUserExists] backs the
/// live lookup as the recipient's phone is typed; [sendToFriend] performs
/// the actual transfer once the sender confirms.
class GiftApiService {
  GiftApiService._();

  /// GET `/users/is-user-exists?phone=...` — whether [phone] belongs to a
  /// registered user. The exact success shape isn't pinned down in the API
  /// contract, so this tolerates a plain boolean `data` as well as
  /// `data: {exists: bool}`, and otherwise treats any 2xx as "exists" (a
  /// 404 is the one shape read as "doesn't exist").
  static Future<bool> checkUserExists({required String phone}) async {
    try {
      _debugLog('checking recipient: ${_maskedPhone(phone)}');
      final response = await DioClient.instance.get(
        AccountEndpoints.isUserExists,
        queryParameters: {'phone': phone},
      );
      // Most API responses are wrapped as `{data: ...}`, but accepting the
      // raw form keeps this compatible with the endpoint's boolean contract.
      // The old lookup read a top-level `{exists: false}` as success, because
      // it only inspected `data`; keep false distinct from a missing value.
      final payload = response.data;
      final data = payload is Map && payload.containsKey('data')
          ? payload['data']
          : payload;
      if (data is bool) {
        _debugLog('recipient ${_maskedPhone(phone)} exists: $data');
        return data;
      }
      if (data is Map && data['exists'] is bool) {
        final exists = data['exists'] as bool;
        _debugLog('recipient ${_maskedPhone(phone)} exists: $exists');
        return exists;
      }
      _debugLog(
        'recipient ${_maskedPhone(phone)} returned an unrecognised success payload; treating as exists: $payload',
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _debugLog('recipient ${_maskedPhone(phone)} does not exist (404)');
        return false;
      }
      _debugLog(
        'recipient check failed for ${_maskedPhone(phone)}: '
        'status=${e.response?.statusCode}, body=${e.response?.data}',
      );
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/users/send-to-friend` `{phone, amount}` — moves [amount] TMT
  /// from the signed-in user's balance to the account at [phone]. The
  /// caller must follow up with [AccountService.refresh] to see the
  /// sender's reduced balance, same contract as every other balance-moving
  /// call in this app (see [AuthApiService.redeemPromoCode]).
  static Future<void> sendToFriend(
      {required String phone, required double amount}) async {
    try {
      _debugLog(
        'sending ${amount.toStringAsFixed(2)} TMT to ${_maskedPhone(phone)}',
      );
      final response = await DioClient.instance.post(
        AccountEndpoints.sendToFriend,
        data: {'phone': phone, 'amount': amount},
      );
      _debugLog(
        'gift sent to ${_maskedPhone(phone)}: '
        'status=${response.statusCode}, body=${response.data}',
      );
    } on DioException catch (e) {
      _debugLog(
        'gift send failed for ${_maskedPhone(phone)}: '
        'status=${e.response?.statusCode}, body=${e.response?.data}',
      );
      throw ApiException.fromDioException(e);
    }
  }

  static String _maskedPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 4)}••••${phone.substring(phone.length - 2)}';
  }

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint('🎁 GiftApiService: $message');
  }
}
