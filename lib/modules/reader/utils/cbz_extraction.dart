import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';

/// File extensions a CBZ page can be. Top-level (not a class member) so
/// [extractCbzOnIsolate] can see it without capturing `this` — see that
/// function's doc for why that matters.
const cbzImageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

/// Orders "page2.jpg" before "page10.jpg" — plain string sort would put
/// "page10" first, scrambling any chapter with 10+ pages. Top-level for the
/// same reason as [cbzImageExtensions].
int compareCbzPagesNaturally(String a, String b) {
  final pattern = RegExp(r'\d+|\D+');
  final partsA = pattern.allMatches(a).map((m) => m.group(0)!).toList();
  final partsB = pattern.allMatches(b).map((m) => m.group(0)!).toList();
  for (var i = 0; i < partsA.length && i < partsB.length; i++) {
    final numA = int.tryParse(partsA[i]);
    final numB = int.tryParse(partsB[i]);
    if (numA != null && numB != null) {
      if (numA != numB) return numA.compareTo(numB);
    } else {
      final c = partsA[i].compareTo(partsB[i]);
      if (c != 0) return c;
    }
  }
  return partsA.length.compareTo(partsB.length);
}

Future<List<String>> _sortedCbzPageFiles(Directory cacheDir) async {
  final entries = await cacheDir.list().toList();
  final files = entries.whereType<File>().where((f) {
    final dot = f.path.lastIndexOf('.');
    return dot != -1 &&
        cbzImageExtensions.contains(f.path.substring(dot).toLowerCase());
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => f.path).toList();
}

/// Unpacks a CBZ's pages onto disk: reads the whole zip into memory, decodes
/// it, and writes one file per page. Runs on a background isolate spawned by
/// [runCbzExtraction] via [Isolate.run] — a 200-500MB scanned manga volume
/// decoded on the UI isolate froze the loading animation and could OOM
/// low-RAM devices, since none of this work yields back to the event loop in
/// a way that keeps the UI responsive.
///
/// Deliberately top-level and free of any State/BuildContext reference:
/// `Isolate.run`'s closure can only capture plain, isolate-sendable data
/// (the `(zipPath, cacheDirPath)` strings below), never `this` or `widget` —
/// capturing either would drag the whole Flutter State object into the
/// isolate-message graph and fail at runtime. [cacheDirPath] is resolved by
/// the caller beforehand for the same reason: getApplicationSupportDirectory()
/// goes through a platform channel, which isn't available off the main
/// isolate without extra plugin-side setup this app doesn't have.
Future<(List<String> pagePaths, bool noImages)> extractCbzOnIsolate(
  (String zipPath, String cacheDirPath) args,
) async {
  final cacheDir = Directory(args.$2);
  final marker = File('${cacheDir.path}/.done');

  if (await marker.exists()) {
    final existing = await _sortedCbzPageFiles(cacheDir);
    if (existing.isNotEmpty) return (existing, false);
  }

  if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
  await cacheDir.create(recursive: true);

  final bytes = await File(args.$1).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  final imageEntries = archive.files.where((f) {
    if (!f.isFile) return false;
    final dot = f.name.lastIndexOf('.');
    if (dot == -1) return false;
    return cbzImageExtensions.contains(f.name.substring(dot).toLowerCase());
  }).toList()
    ..sort((a, b) => compareCbzPagesNaturally(a.name, b.name));

  if (imageEntries.isEmpty) return (const <String>[], true);

  final paths = <String>[];
  for (var i = 0; i < imageEntries.length; i++) {
    final entry = imageEntries[i];
    final data = entry.readBytes();
    if (data == null) continue;
    final ext = entry.name.substring(entry.name.lastIndexOf('.'));
    final pagePath = '${cacheDir.path}/${i.toString().padLeft(5, '0')}$ext';
    await File(pagePath).writeAsBytes(data, flush: true);
    paths.add(pagePath);
  }

  if (paths.isEmpty) return (const <String>[], true);

  await marker.create();
  return (paths, false);
}

/// Spawns the isolate for [extractCbzOnIsolate]. Kept as its own top-level
/// function — not inlined into the caller — so the `Isolate.run` closure
/// never shares a lexical scope/context with the caller's other closures
/// (its `setState` callbacks, which do capture `this`). Dart can allocate
/// one shared context object per scope, so even a closure that only touches
/// [args] here can end up dragging `this` — and the `Timer` fields hanging
/// off it — into the isolate message if it's declared alongside closures
/// that need `this`. Giving it a scope of its own avoids that entirely.
Future<(List<String> pagePaths, bool noImages)> runCbzExtraction(
  (String zipPath, String cacheDirPath) args,
) {
  return Isolate.run(() => extractCbzOnIsolate(args));
}
