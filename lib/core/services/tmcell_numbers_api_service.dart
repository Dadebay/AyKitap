import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import '../network/dio_client.dart';
import '../network/payment_endpoints.dart';

/// The TMCELL lines a balance transfer may be sent to, read from
/// `GET /tmcell/numbers`.
///
/// This used to be a build-time `--dart-define`, which meant the receiving
/// number could only be changed by shipping a new build — and a SIM that
/// stops working (lost, blocked, out of service) silently sends every
/// reader's money nowhere until that build reaches them. The admin panel now
/// owns the list, and the backend matches an incoming transfer against the
/// same rows, so what the app sends to and what the server credits from can
/// no longer drift apart.
class TmcellNumbersApiService {
  TmcellNumbersApiService._();

  /// Cached for the session. The list changes about as often as a SIM card
  /// does, and the top-up screen is opened repeatedly while a reader decides
  /// on an amount — re-asking on every visit would be a request per visit
  /// for an answer that is the same every time.
  static List<String>? _cached;

  /// Every active line, in the order the admin sorted them.
  static Future<List<String>> getNumbers({bool forceRefresh = false}) async {
    final cached = _cached;
    if (cached != null && !forceRefresh) {
      _log('cache hit — ${cached.length} number(s): ${cached.join(", ")}');
      return cached;
    }
    _log('GET ${PaymentEndpoints.tmcellNumbers} …');
    try {
      final response =
          await DioClient.instance.get(PaymentEndpoints.tmcellNumbers);
      final list = response.data['data'] as List? ?? const [];
      final numbers = list
          .map((e) => (e as Map<String, dynamic>)['phone'] as String? ?? '')
          .where((phone) => phone.isNotEmpty)
          .toList();
      _cached = numbers;
      if (numbers.isEmpty) {
        // The request worked and the admin panel simply has no active line —
        // a different problem from a failed request, and the screen says
        // something different for each, so the log has to as well.
        _log('OK but EMPTY — no active number in the admin panel '
            '(raw list: ${list.length} row(s))');
      } else {
        _log('OK — ${numbers.length} number(s): ${numbers.join(", ")} '
            '→ using "${numbers.first}"');
      }
      return numbers;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _log('FAILED — ${status ?? e.type.name}: ${e.message ?? e.error}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Cyan, so a top-up run can be read at a glance next to the purple
  /// purchase lines and the yellow search ones. Debug builds only.
  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('\x1B[36m\x1B[1m📱 TMCELL numbers — $message\x1B[0m');
  }

  /// The line a transfer should go to, or null when the admin panel has no
  /// active number at all.
  ///
  /// The first one rather than a random pick: every active number is credited
  /// the same way, so there is nothing to gain from spreading transfers
  /// across them, and a number that stays put is one a reader can recognise
  /// in their SMS history the second time they top up.
  static Future<String?> getReceiver({bool forceRefresh = false}) async {
    final numbers = await getNumbers(forceRefresh: forceRefresh);
    return numbers.isEmpty ? null : numbers.first;
  }

  /// Drops the cache — for a pull-to-refresh or a retry after a failure.
  static void invalidate() => _cached = null;
}
