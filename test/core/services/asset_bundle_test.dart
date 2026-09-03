import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the asset-bundle cleanup in `.Codex/ASSET_AUDIT.md`: the Play
/// Store screenshot must stay out of the runtime bundle (moved to
/// `docs/store-assets/`, kept as release material rather than deleted), and
/// the duplicate `assets/logo.webp` must have been fully replaced by
/// `assets/images/logo.webp` with no dangling reference to the old path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Play Store screenshot is no longer a bundled asset', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    expect(
      assets.any((a) => a.contains('aykitap-play-screenshot-01')),
      isFalse,
      reason: 'the screenshot was moved to docs/store-assets/, '
          'not left in the runtime bundle',
    );
  });

  test('the duplicate assets/logo.webp is gone; the canonical path remains',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    expect(assets.contains('assets/logo.webp'), isFalse);
    expect(assets.contains('assets/images/logo.webp'), isTrue);

    // The canonical copy still actually loads, not just listed.
    final bytes = await rootBundle.load('assets/images/logo.webp');
    expect(bytes.lengthInBytes, greaterThan(0));
  });

  test('other collection asset categories are unaffected by the cleanup',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    expect(assets, contains('assets/animations/book_idea.json'));
    expect(assets, contains('assets/flags/tm.svg'));
    expect(assets, contains('assets/icons/reader/transition_slide.png'));
  });
}
