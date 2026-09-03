// Regression cover for NetworkCoverImage's decode-size calculation.
//
// It used to size memCacheWidth off `math.max(boxWidth, boxHeight)` with
// memCacheHeight left null — for a portrait book cover (width < height),
// that decoded the bitmap as wide as the cover is *tall*, noticeably
// bigger than it's ever drawn, and let the source's own aspect ratio (not
// the target box's) decide the resulting height.
import 'package:aykitap/core/widgets/network_cover_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = 'https://example.com/cover.jpg';

Widget _app(Widget child, {double dpr = 3}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(devicePixelRatio: dpr),
        child: Scaffold(body: child),
      ),
    );

CachedNetworkImage _cached(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

void main() {
  testWidgets('100x155 at DPR 3 decodes ~300x465 — width does not become 465',
      (tester) async {
    await tester.pumpWidget(_app(
      const SizedBox(
        width: 100,
        height: 155,
        child: NetworkCoverImage(
          url: _url,
          placeholder: _placeholder,
        ),
      ),
    ));

    final image = _cached(tester);
    expect(image.memCacheWidth, 300);
    expect(image.memCacheHeight, 465);
    // The specific regression: memCacheWidth must track the box's own
    // width (300), not its height (465) via `math.max`.
    expect(image.memCacheWidth, isNot(465));
  });

  testWidgets('only width given sizes memCacheWidth and leaves height null',
      (tester) async {
    await tester.pumpWidget(_app(
      // The explicit `width` prop, not an ambient constraint — a vertical
      // scroller also leaves height genuinely unbounded, so there's no
      // ambient ceiling (e.g. Scaffold's own full-page height) quietly
      // supplying one instead.
      const SingleChildScrollView(
        child:
            NetworkCoverImage(url: _url, width: 120, placeholder: _placeholder),
      ),
      dpr: 2,
    ));

    final image = _cached(tester);
    expect(image.memCacheWidth, 240);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets('only height given sizes memCacheHeight and leaves width null',
      (tester) async {
    await tester.pumpWidget(_app(
      // Mirror of the width-only case: a horizontal scroller leaves width
      // genuinely unbounded, isolating the explicit `height` prop.
      const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: NetworkCoverImage(
            url: _url, height: 200, placeholder: _placeholder),
      ),
      dpr: 2,
    ));

    final image = _cached(tester);
    expect(image.memCacheHeight, 400);
    expect(image.memCacheWidth, isNull);
  });

  testWidgets('an explicit decodeCacheWidth wins over width/height',
      (tester) async {
    await tester.pumpWidget(_app(
      const SizedBox(
        width: 100,
        height: 155,
        child: NetworkCoverImage(
          url: _url,
          decodeCacheWidth: 650,
          placeholder: _placeholder,
        ),
      ),
    ));

    final image = _cached(tester);
    expect(image.memCacheWidth, 650);
    // The auto-computed height is skipped entirely once decodeCacheWidth is
    // explicit — CachedNetworkImage/ResizeImage scales height off the
    // source's own aspect ratio, same as before this fix.
    expect(image.memCacheHeight, isNull);
  });

  testWidgets(
      'an unbounded axis (infinite constraint, no explicit size) sets no '
      'cache size for that axis rather than an invalid one', (tester) async {
    await tester.pumpWidget(_app(
      // A horizontal scroller hands its child an *unbounded* width — the
      // child decides its own scroll-axis extent — while the fixed-height
      // SizedBox keeps the cross axis finite. No explicit width is given
      // to NetworkCoverImage either, so its own boxWidth genuinely has
      // nothing finite to resolve to.
      const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 90,
          child: NetworkCoverImage(url: _url, placeholder: _placeholder),
        ),
      ),
    ));

    final image = _cached(tester);
    // The finite axis (height) still gets a real, positive cache size.
    expect(image.memCacheHeight, isNotNull);
    expect(image.memCacheHeight, greaterThan(0));
    // The unbounded axis (width) must never reach CachedNetworkImage as
    // an infinite, zero, or negative cache size — leaving it unset (null)
    // is the only valid outcome here.
    expect(image.memCacheWidth, isNull);
  });

  testWidgets('both width and height given pass both to CachedNetworkImage',
      (tester) async {
    await tester.pumpWidget(_app(
      const NetworkCoverImage(
        url: _url,
        width: 152,
        height: 224,
        placeholder: _placeholder,
      ),
      dpr: 2,
    ));

    final image = _cached(tester);
    expect(image.memCacheWidth, 304);
    expect(image.memCacheHeight, 448);
  });

  testWidgets(
      'a very large box/DPR combination is capped, not decoded at '
      'thousands of pixels', (tester) async {
    await tester.pumpWidget(_app(
      const NetworkCoverImage(
        url: _url,
        width: 2000,
        height: 3000,
        placeholder: _placeholder,
      ),
      dpr: 4,
    ));

    final image = _cached(tester);
    // 2000*4=8000 and 3000*4=12000 uncapped — both must be clamped well
    // below "decode a multi-thousand-pixel bitmap for a cover thumbnail".
    expect(image.memCacheWidth, lessThanOrEqualTo(2048));
    expect(image.memCacheHeight, lessThanOrEqualTo(2048));
  });

  testWidgets('BoxFit.cover is preserved by default', (tester) async {
    await tester.pumpWidget(_app(
      const NetworkCoverImage(url: _url, placeholder: _placeholder),
    ));

    expect(_cached(tester).fit, BoxFit.cover);
  });

  testWidgets('an explicit fit overrides the default', (tester) async {
    await tester.pumpWidget(_app(
      const NetworkCoverImage(
        url: _url,
        fit: BoxFit.contain,
        placeholder: _placeholder,
      ),
    ));

    expect(_cached(tester).fit, BoxFit.contain);
  });
}

Widget _placeholder(BuildContext context) => const SizedBox.shrink();
