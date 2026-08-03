import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/models/author_detail.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../author/catalog_author_detail_screen.dart';

/// One `GET /authors/search` hit in [SearchScreen]'s "Ýazar" mode.
///
/// A full-width row rather than the square grid cell Home uses: a search hit
/// is picked by *reading the name*, so the name gets a full line of width and
/// a readable size instead of being squeezed into 11.5px under an avatar,
/// and the `book_count` the endpoint already returns is shown instead of
/// being thrown away. Flat surfaces only (no gradients) — the avatar reads as
/// a portrait via a hairline ring, and the count sits in a soft primary-tint
/// chip.
class AuthorResultCard extends StatefulWidget {
  final AuthorSearchResult author;
  const AuthorResultCard({super.key, required this.author});

  @override
  State<AuthorResultCard> createState() => _AuthorResultCardState();
}

class _AuthorResultCardState extends State<AuthorResultCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  /// Up to two initials ("Gurbanguly Berdimuhamedow" -> "GB") — a named
  /// fallback reads far better than the same generic person glyph repeated
  /// down a list of authors with no photo.
  String get _initials {
    final parts = widget.author.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p.characters.first).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.author.image;
    final hasImage = image != null && image.isNotEmpty;
    return GestureDetector(
      onTap: () => context.push(CatalogAuthorDetailScreen(authorId: widget.author.id)),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.card : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _pressed ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border),
          ),
          child: Row(
            children: [
              // Hairline ring + inner gap, so the portrait keeps a little air
              // around it instead of butting straight against the card.
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipOval(
                  child: hasImage
                      ? NetworkCoverImage(
                          url: ApiConfig.resolveImageUrl(image),
                          // Author portraits are shot with the head above
                          // the middle, so a centered square crop tends to
                          // cut the top of it off.
                          alignment: const Alignment(0, -0.35),
                          placeholder: (_) => _initialsAvatar(),
                        )
                      : _initialsAvatar(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.author.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.primary, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            AuthorStrings.booksCountLabel(widget.author.bookCount),
                            style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar() => Container(
        color: AppColors.primary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: TextStyle(color: AppColors.primary, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      );
}
