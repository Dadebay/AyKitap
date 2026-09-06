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
  bool _disposed = false;

  List<BalanceLog>? get logs => _logs;
  List<PaymentOrder>? get orders => _orders;
  String? get error => _error;

  Future<void> load() async {
    await Future.wait([loadLogs(), loadOrders()]);
  }

  Future<void> loadLogs() async {
    if (_disposed) return;
    _error = null;
    _notifyIfActive();
    try {
      final logs = await BalanceLogApiService.listLogs();
      if (_disposed) return;
      _logs = logs;
    } on ApiException catch (error) {
      if (_disposed) return;
      _error = error.message;
    }
    _notifyIfActive();
  }

  Future<void> loadOrders() async {
    if (_disposed) return;
    try {
      final orders = await PaymentApiService.getMyOrders();
      if (_disposed) return;
      _orders = orders;
    } on ApiException {
      if (_disposed) return;
      _orders = const [];
    }
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
