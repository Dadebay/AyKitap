import 'package:flutter/foundation.dart';
import 'auth_session.dart';

/// Reactive cache of the signed-in user's chosen avatar (preset index or
/// custom photo) — [AuthSession] only persists these, it doesn't notify
/// anyone when they change. [WheelNavBar]'s profile tab icon listens here
/// so it updates the moment [EditProfileScreen] saves a new photo, rather
/// than only picking it up on the next cold start.
class ProfileAvatarService extends ChangeNotifier {
  ProfileAvatarService._();
  static final instance = ProfileAvatarService._();

  int _index = -1;
  String? _image;

  int get index => _index;
  String? get image => _image;

  /// Re-reads both from [AuthSession] — call once on app start (or whenever
  /// a caller doesn't already have the freshly-saved values on hand; if it
  /// does, [set] avoids the redundant read).
  Future<void> load() async {
    _index = await AuthSession.getAvatar();
    _image = await AuthSession.getAvatarImage();
    notifyListeners();
  }

  /// Updates the cache directly from values a caller just saved to
  /// [AuthSession] itself, skipping the read [load] would otherwise repeat.
  void set({required int index, required String? image}) {
    _index = index;
    _image = image;
    notifyListeners();
  }
}
