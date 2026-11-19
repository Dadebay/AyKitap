import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/strings/next_book_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/services/book_recommendation_service.dart';

/// A small, text-only offer; it does not decode another cover on low-RAM
/// phones while a WebView/PDF renderer is still alive.
class NextBookOffer extends StatefulWidget {
  const NextBookOffer(
      {super.key,
      required this.finishedBookId,
      required this.onOpen,
      required this.foreground,
      required this.background});

  final int finishedBookId;
  final Future<void> Function(LibraryBook book) onOpen;
  final Color foreground;
  final Color background;

  @override
  State<NextBookOffer> createState() => _NextBookOfferState();
}

class _NextBookOfferState extends State<NextBookOffer> {
  LibraryBook? _book;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOffer());
  }

  @override
  void didUpdateWidget(NextBookOffer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.finishedBookId != widget.finishedBookId) {
      _book = null;
      unawaited(_loadOffer());
    }
  }

  Future<void> _loadOffer() async {
    final bookId = widget.finishedBookId;
    final requestId = ++_requestId;
    try {
      final recommendation =
          await BookRecommendationService.instance.suggest(bookId);
      if (mounted && requestId == _requestId) {
        setState(() => _book = recommendation);
      }
    } catch (_) {
      // A recommendation is optional; offline reading must still work.
    }
  }

  @override
  Widget build(BuildContext context) => _buildOffer(_book);

  Widget _buildOffer(LibraryBook? book) {
    if (book == null) return const SizedBox.shrink();
    final foreground = widget.foreground;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: widget.background,
            elevation: 3,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onOpen(book),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  Icon(Icons.auto_stories_rounded, color: foreground, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(NextBookStrings.title,
                          style: TextStyle(
                              color: foreground.withValues(alpha: 0.7),
                              fontSize: 11)),
                      Text(book.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      color: foreground, size: 18),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
