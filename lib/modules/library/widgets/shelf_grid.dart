import 'package:flutter/material.dart';

/// Lays [itemCount] items out across repeating wooden-shelf "compartments"
/// of up to 3 upright covers each, matching the TZ section-7 reference
/// (Surat 5). Shared by the mock catalogue tabs and the own-books tab —
/// [itemBuilder] supplies the cover widget, the shelf just provides slots.
/// Not scrollable itself: the caller wraps it in whatever scroll view fits
/// (a bare scroller for a full-tab grid, or one shared ListView alongside
/// other header content, as in `OwnBooksTab`).
class ShelfGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  const ShelfGrid(
      {super.key, required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    const perShelf = 3;
    final shelfCount = (itemCount / perShelf).ceil();
    return Column(
      children: List.generate(shelfCount, (shelfIndex) {
        final start = shelfIndex * perShelf;
        return _ShelfRow(
          slots: List.generate(3, (i) {
            final idx = start + i;
            return idx < itemCount ? itemBuilder(context, idx) : null;
          }),
        );
      }),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final List<Widget?> slots;
  const _ShelfRow({required this.slots});

  static const double _imageAspect = 3 / 1.60;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _imageAspect,
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
