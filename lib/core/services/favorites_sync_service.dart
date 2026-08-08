import 'package:flutter/foundation.dart';

/// Pinged by [CatalogBookDetailScreen]'s favorite toggle so
/// [LibraryScreen]'s "Halanan" (favorites / `wants_to`) tab knows to
/// re-fetch. That tab is kept alive across tab switches
/// ([ApiBooksTab]'s `AutomaticKeepAliveClientMixin`), so without this a
/// book liked/unliked elsewhere in the app only shows up there after a
/// manual pull-to-refresh.
class FavoritesSyncService extends ChangeNotifier {
  FavoritesSyncService._();
  static final instance = FavoritesSyncService._();

  void notifyChanged() => notifyListeners();
}
