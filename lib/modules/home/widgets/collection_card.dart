import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book.dart';
import '../../../core/localization/strings/home_strings.dart';

/// A "Kolleksiýalar" shelf card — emoji badge, title, and book count over a
/// themed gradient background.
class CollectionCard extends StatelessWidget {
  final BookCollection collection;
  const CollectionCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: collection.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: collection.gradient.last.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Center(child: Text(collection.emoji, style: const TextStyle(fontSize: 22))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collection.title,
                style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
                    child: Text(HomeStrings.bookCount(collection.books.length), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 14)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
