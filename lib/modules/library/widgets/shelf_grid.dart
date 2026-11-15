import 'package:flutter/material.dart';
import '../../home/widgets/stagger_fade_in.dart';

/// Lays [itemCount] items out across repeating wooden-shelf "compartments"
/// of up to 3 (4 on a tablet) upright covers each, matching the TZ section-7 reference
/// (Surat 5). Shared by the mock catalogue tabs and the own-books tab —
/// [itemBuilder] supplies the cover widget, the shelf just provides slots.
/// A sliver so only visible shelf rows and their cover images are built.
/// Place it directly inside a [CustomScrollView].
///
/// Staggered by shelf row (not by individual cover — three covers landing
/// on the same wooden shelf at once reads as one unit, matching the row
/// stagger [CatalogCollectionBooksScreen]'s grid uses for the same reason).
class ShelfGridSliver extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  const ShelfGridSliver(
      {super.key, required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    // Tablet: four covers per shelf instead of three huge ones.
    final perShelf = MediaQuery.sizeOf(context).width >= 700 ? 4 : 3;
    final shelfCount = (itemCount / perShelf).ceil();
    return SliverList.builder(
      itemCount: shelfCount,
      itemBuilder: (context, shelfIndex) {
        final start = shelfIndex * perShelf;
        return StaggerFadeIn(
          index: shelfIndex,
          keepAlive: false,
          child: _ShelfRow(
            slots: List.generate(perShelf, (i) {
              final idx = start + i;
              return idx < itemCount ? itemBuilder(context, idx) : null;
            }),
          ),
        );
      },
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final List<Widget?> slots;
  const _ShelfRow({required this.slots});

  /// Width : height of one shelf compartment, per cover. Scales with the
  /// number of covers so the shelf keeps the same height-per-cover whether it
  /// holds three or four.
  static const double _aspectPerCover = 1 / 1.60;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: slots.length * _aspectPerCover,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/shelf_wood.webp', fit: BoxFit.fill),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: slots.map((slot) {
                return Expanded(
                  child: slot == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: slot),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
