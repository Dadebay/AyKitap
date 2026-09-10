import 'package:aykitap/core/widgets/network_cover_image.dart';
import 'package:aykitap/modules/home/widgets/catalog_author_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'preserves an author portrait aspect ratio inside its avatar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CatalogAuthorAvatar(
            authorId: 1,
            name: 'Portrait Author',
            image: 'authors/portrait.jpg',
          ),
        ),
      ),
    );

    final image =
        tester.widget<NetworkCoverImage>(find.byType(NetworkCoverImage));
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);
    // One cache dimension preserves the original portrait ratio.
    expect(image.decodeCacheWidth, isNotNull);
  });
}
