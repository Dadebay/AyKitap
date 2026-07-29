import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Shrinks a picked photo down to the backend's avatar upload limit before
/// it's base64-encoded and sent in a PATCH `/users` body — a raw camera/
/// gallery photo (often several MB) would otherwise blow well past it.
class ImageCompressor {
  ImageCompressor._();

  static const int maxBytes = 1024 * 1024;
  static const int _maxDimension = 1024;
  static const List<int> _qualitySteps = [85, 75, 65, 55, 45, 35, 25, 15];

  /// Re-encodes [bytes] as JPEG, capping the longest side at [_maxDimension]
  /// and stepping quality down, until the result is at or under [maxBytes].
  /// Returns the original bytes unchanged if they already fit; null if
  /// [bytes] isn't a decodable image.
  static Uint8List? compress(Uint8List bytes) {
    if (bytes.length <= maxBytes) return bytes;

    var image = img.decodeImage(bytes);
    if (image == null) return null;

    if (image.width > _maxDimension || image.height > _maxDimension) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? _maxDimension : null,
        height: image.height > image.width ? _maxDimension : null,
      );
    }

    for (final quality in _qualitySteps) {
      final encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (encoded.length <= maxBytes) return encoded;
    }

    // Still over the limit at the lowest quality step — an oversized source
    // image (e.g. a wide panorama) — so halve the dimensions once more and
    // settle for a middling quality; this is a profile photo shown at ~88px,
    // it doesn't need to stay large to still look fine.
    image = img.copyResize(image, width: (image.width / 2).round());
    return Uint8List.fromList(img.encodeJpg(image, quality: 40));
  }
}
