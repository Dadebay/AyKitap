import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../author/catalog_author_detail_screen.dart';

/// Photo-forward author card — replaces the old circular-avatar treatment
/// ([CatalogAuthorAvatar] on Home, the flat row [AuthorResultCard] on
/// Search) with one reusable widget both screens build from: a 2:3 portrait
/// photo with the name and a book-count/"Author" badge underneath.
///
/// Deliberately model-agnostic (`authorId`/`name`/`image`/`bookCount`
/// instead of taking a [LibraryBookAuthor] or [AuthorSearchResult] directly)
/// since the two call sites feed it from different response shapes — Home's
/// collection row has no `book_count`, only Search's `GET /authors/search`
/// does.
class CatalogAuthorCard extends StatelessWidget {
  const CatalogAuthorCard({
    super.key,
    required this.authorId,
    required this.name,
    this.image,
    this.bookCount,
    this.width,
  });

  final int authorId;
  final String name;
  final String? image;

  /// Shown as a "N kitap" badge when given; falls back to a generic
  /// [AuthorStrings.authorLabel] badge when null (Home has no count to show).
  final int? bookCount;

  /// Fixed width for Home's horizontal rail; leave null to fill the parent
  /// (Search's grid cell sizes it instead — see [AuthorResultGrid]).
  final double? width;

  /// Up to two initials ("Gurbanguly Berdimuhamedow" -> "GB") for the
  /// no-photo placeholder — a named fallback reads far better than a
  /// generic person glyph repeated down a list of authors with no photo.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.isNotEmpty;
    return Semantics(
      label: name,
      button: true,
      child: PressableScale(
        onTap: () => context.push(CatalogAuthorDetailScreen(authorId: authorId)),
        child: SizedBox(
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: hasImage
                        ? NetworkCoverImage(
                            url: ApiConfig.resolveImageUrl(image!),
                            // Author portraits are shot with the head above
                            // the middle, so a centered crop tends to cut
                            // the top of it off.
                            fit: BoxFit.contain,
                            alignment: const Alignment(0, -0.35),
                            placeholder: (_) => _monogram(),
                          )
                        : _monogram(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.25),
                ),
                const SizedBox(height: 6),
                _infoBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The Journey-gradient placeholder shown while a photo is loading, or in
  /// place of one entirely when this author has none.
  Widget _monogram() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.journeyPrimary),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _infoBadge() {
    final count = bookCount;
    final label = count != null ? AuthorStrings.booksCountLabel(count) : AuthorStrings.authorLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: count != null ? HugeIcons.strokeRoundedBook02 : HugeIcons.strokeRoundedUser, color: AppColors.primary, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
