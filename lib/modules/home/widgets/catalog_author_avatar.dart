import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../author/catalog_author_detail_screen.dart';

/// A single avatar + name cell for a real [LibraryBookAuthor] — the
/// real-catalogue counterpart to Home's mock `AuthorAvatar`, used in a
/// `type: "author"` [Collection]'s row. Tapping opens
/// [CatalogAuthorDetailScreen] (`GET /authors/:id`).
///
/// A plain flat [AppColors.surface] chip (no gradient — a translucent tint
/// read as muddy in dark mode) with a hairline border frames the story-ring
/// gradient avatar — the ring's own background-color gap keeps it reading
/// as a ring rather than a solid gradient disc — plus a springy press-down
/// for tactile feedback, same touch as the rest of the app's interactive
/// chips.
class CatalogAuthorAvatar extends StatefulWidget {
  final LibraryBookAuthor author;
  // Fixed 120 for Home's horizontal row (each item needs its own intrinsic
  // width there); pass `double.infinity` to fill a grid cell instead, as
  // [SearchScreen]'s author-mode results grid does.
  final double width;
  const CatalogAuthorAvatar({super.key, required this.author, this.width = 120});

  @override
  State<CatalogAuthorAvatar> createState() => _CatalogAuthorAvatarState();
}

class _CatalogAuthorAvatarState extends State<CatalogAuthorAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    _press.animateTo(pressed ? 0.9 : 1, duration: Duration(milliseconds: pressed ? 100 : 220), curve: pressed ? Curves.easeOut : Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.author.image;
    return GestureDetector(
      onTap: () => context.push(CatalogAuthorDetailScreen(authorId: widget.author.id)),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: ScaleTransition(
        scale: _press,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(2.2),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.coralPurple),
                child: Container(
                  padding: const EdgeInsets.all(2.2),
                  // Matches the (now solid) card behind it so the ring's
                  // gap blends in rather than punching a visible hole.
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: ClipOval(
                    child: image != null && image.isNotEmpty ? NetworkCoverImage(fit: BoxFit.contain, url: ApiConfig.resolveImageUrl(image), placeholder: (_) => _placeholder()) : _placeholder(),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                widget.author.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.grey1, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.card,
        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey3, size: 26)),
      );
}
