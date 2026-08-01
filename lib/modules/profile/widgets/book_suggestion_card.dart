import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book_suggestion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/profile_strings.dart';

class BookSuggestionCard extends StatelessWidget {
  final BookSuggestion suggestion;
  final VoidCallback? onDelete;
  final bool isDeleting;

  const BookSuggestionCard({
    super.key,
    required this.suggestion,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = _StatusDisplay.of(suggestion.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Center(
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedBookOpen01,
                        color: AppColors.primary,
                        size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.name,
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(suggestion.author,
                        style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: status),
                  if (onDelete != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.redAccent),
                            )
                          : IconButton(
                              tooltip: ProfileStrings.deleteBookRequest,
                              padding: EdgeInsets.zero,
                              onPressed: onDelete,
                              icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete02,
                                  color: Colors.redAccent,
                                  size: 18),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (suggestion.description != null &&
              suggestion.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(suggestion.description!,
                style: TextStyle(
                    color: AppColors.grey1, fontSize: 13, height: 1.4)),
          ],
          if (suggestion.status == 'rejected' &&
              suggestion.rejectedReason != null &&
              suggestion.rejectedReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(suggestion.rejectedReason!,
                style: TextStyle(
                    color: Colors.redAccent.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusDisplay status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: status.icon, color: status.color, size: 12),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusDisplay {
  final String label;
  final Color color;
  final List<List<dynamic>> icon;
  const _StatusDisplay(
      {required this.label, required this.color, required this.icon});

  factory _StatusDisplay.of(String status) {
    switch (status) {
      case 'accepted':
        return _StatusDisplay(
            label: ProfileStrings.suggestionStatusAccepted,
            color: const Color(0xFF3FBE6C),
            icon: HugeIcons.strokeRoundedCheckmarkCircle01);
      case 'rejected':
        return _StatusDisplay(
            label: ProfileStrings.suggestionStatusRejected,
            color: Colors.redAccent,
            icon: HugeIcons.strokeRoundedCancelCircle);
      default:
        return _StatusDisplay(
            label: ProfileStrings.suggestionStatusPending,
            color: AppColors.grey2,
            icon: HugeIcons.strokeRoundedClock01);
    }
  }
}
