import 'package:flutter/material.dart';

/// Kills the `Navigator.push(context, MaterialPageRoute(builder: (_) => X()))`
/// boilerplate repeated at every call site — this is a plain `MaterialPageRoute`
/// push, nothing more.
extension AppNavigator on BuildContext {
  Future<T?> push<T>(Widget screen) => Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));

  void pop<T>([T? result]) => Navigator.pop(this, result);
}
