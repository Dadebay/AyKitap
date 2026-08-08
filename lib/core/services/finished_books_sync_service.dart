import 'package:flutter/foundation.dart';

/// Notifies the completed-books library shelf after a book's reading
/// progress has successfully been synced as 100%.
class FinishedBooksSyncService extends ChangeNotifier {
  FinishedBooksSyncService._();
  static final instance = FinishedBooksSyncService._();

  void notifyChanged() => notifyListeners();
}
