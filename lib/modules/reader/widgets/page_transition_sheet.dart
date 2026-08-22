import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';
import 'transition_meta.dart';
import 'transition_tile.dart';

/// The "Sahypa çalyşmak" popup: a centred title with a close button, two rows
/// of three page-change styles, and the "flip with the left hand" toggle.
class PageTransitionSheet extends StatelessWidget {
  const PageTransitionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Centred title, with a close button balanced by an equal-width
              // spacer on the left so the text doesn't drift off-centre.
              Row(
                children: [
                  const SizedBox(width: 30),
                  Expanded(
                    child: Text(
                      ReaderStrings.pageTransitionTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: AppColors.card, shape: BoxShape.circle),
                      child:
                          Icon(Icons.close, color: AppColors.grey2, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row(provider, const [
                        ReaderPageTransition.slide,
                        ReaderPageTransition.curl,
                        ReaderPageTransition.overlay,
                      ]),
                      const SizedBox(height: 14),
                      _row(provider, const [
                        ReaderPageTransition.scroll,
                        ReaderPageTransition.shift,
                        ReaderPageTransition.none,
                      ]),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(ReaderProvider provider, List<ReaderPageTransition> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: TransitionTile(
              asset: transitionIcons[items[i]]!,
              label: transitionLabel(items[i]),
              selected: provider.pageTransition == items[i],
              onTap: () => provider.setPageTransition(items[i]),
            ),
          ),
        ],
      ],
    );
  }
}
