import 'package:flutter/foundation.dart';

import '../../../core/models/balance_log.dart';
import '../../../core/models/payment_order.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/balance_log_api_service.dart';
import '../../../core/services/payment_api_service.dart';

/// Owns remote balance history state; the selected visible tab remains local UI state.
class BalanceController extends ChangeNotifier {
  List<BalanceLog>? _logs;
  List<PaymentOrder>? _orders;
  String? _error;

  List<BalanceLog>? get logs => _logs;
  List<PaymentOrder>? get orders => _orders;
  String? get error => _error;

  Future<void> load() async {
    await Future.wait([loadLogs(), loadOrders()]);
  }

  Future<void> loadLogs() async {
    _error = null;
    notifyListeners();
    try {
      _logs = await BalanceLogApiService.listLogs();
    } on ApiException catch (error) {
      _error = error.message;
    }
    notifyListeners();
  }

  Future<void> loadOrders() async {
    try {
      _orders = await PaymentApiService.getMyOrders();
    } on ApiException {
      _orders = const [];
    }
    notifyListeners();
  }
}
