import 'package:material_ui/material_ui.dart';
import '../theme/app_text_styles.dart';

/// The "title (+ optional subtitle) / see-all link" row repeated at the top
/// of every horizontal section on Home (Popular, Collections, Series,
/// Authors, genre rows) and reused wherever a list needs the same header.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
    this.large = false,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
  });

  final String title;
  final String? subtitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final bool large;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: large ? AppTextStyles.sectionTitle.copyWith(fontSize: 21) : AppTextStyles.sectionTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: large ? AppTextStyles.sectionSubtitle.copyWith(fontSize: 15) : AppTextStyles.sectionSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(seeAllLabel ?? '', style: large ? AppTextStyles.link.copyWith(fontSize: 15) : AppTextStyles.link),
              ),
            ),
        ],
      ),
    );
  }
}
