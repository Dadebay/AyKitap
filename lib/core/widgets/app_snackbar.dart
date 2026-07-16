import 'package:flutter/material.dart';

/// Replaces the raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`
/// repeated across 10 screens with a one-line call.
extension AppSnackBar on BuildContext {
  void showAppSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
