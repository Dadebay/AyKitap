import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/book.dart';
import '../../../core/theme/app_colors.dart';

/// The blurred-cover hero at the top of Book Detail (§10.1.1–2): a
/// backdrop-blurred copy of the cover and the sharp main cover near the
/// bottom. Purely decorative background art — it's meant to sit pinned
/// behind the scrolling content sheet (which can slide up and cover it),
/// so the back/flag/favorite/share row lives separately in
/// [DetailHeaderControls] and is layered on top of everything by the
/// caller, where it stays tappable no matter how far the sheet has scrolled.
class DetailHeaderArt extends StatelessWidget {
  const DetailHeaderArt({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred bg cover (§10.1.1). ClipRect is required here — an
          // unclipped BackdropFilter blurs the full scene layer rather than
          // just this Stack's bounds, so it visibly bleeds into the sliver
          // content below until a later frame (e.g. a scroll) forces Flutter
          // to re-establish the layer bounds.
          Image.asset(book.coverImage, fit: BoxFit.cover),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: book.coverColor.withValues(alpha: 0.55)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg.withValues(alpha: 0.4), AppColors.bg],
                stops: const [0.4, 0.82, 1.0],
              ),
            ),
          ),
          // Main cover (§10.1.2)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 65,
            child: Center(
              child: Container(
                width: 152,
                height: 224,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  // Two layered shadows — a tight dark one for a crisp edge
                  // right under the cover, and a wider soft one that lifts it
                  // off the blurred backdrop — so the sharp cover clearly
                  // reads as a separate card floating over the blur, not
                  // part of it.
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 36, spreadRadius: 2, offset: const Offset(0, 18)),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(book.coverImage, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
