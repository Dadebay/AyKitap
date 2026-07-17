import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A stable integer key for [id], for use anywhere a book/file identity is
/// persisted as an `int` — progress, bookmark, and highlight lookups keyed by
/// `book_{key}_...` prefs entries, cache folder names, and the like.
///
/// `Object.hashCode` is explicitly *not* guaranteed to be the same across
/// runs of the VM (per the Dart docs), let alone across Dart/Flutter SDK
/// upgrades — a value that changed under an app update would silently orphan
/// every saved progress/bookmark/highlight keyed by the old hash. This is a
/// pure function of [id]'s bytes instead: the same string always maps to the
/// same int, on any Dart version, on any device.
int stableBookKey(String id) {
  final digest = md5.convert(utf8.encode(id));
  final bytes = digest.bytes;
  // First 4 digest bytes as a non-negative 32-bit int — ample keyspace for
  // this app's book count, and shaped like the plain ints these keys already
  // used.
  return (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]) & 0x7FFFFFFF;
}
