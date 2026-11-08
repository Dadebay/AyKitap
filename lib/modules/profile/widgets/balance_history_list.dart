import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../provider/balance_controller.dart';
import 'balance_history_tiles.dart';

/// [BalanceScreen]'s "Balans taryhy" tab body — loading/error/empty states
/// plus the actual log list, pull-to-refresh included.
class BalanceHistoryList extends StatelessWidget {
  const BalanceHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BalanceController>();
    if (controller.logs == null && controller.error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: TextButton(
            onPressed: controller.loadLogs,
            child: Text(ProfileStrings.retry,
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    final logs = controller.logs!;
    if (logs.isEmpty) return const _HistoryEmpty();
    return RefreshIndicator(
      onRefresh: controller.loadLogs,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, index) => BalanceLogTile(log: logs[index]),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppTheme>().isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                isDark
                    ? 'assets/images/balance_empty_dark.webp'
                    : 'assets/images/balance_empty_light.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ProfileStrings.balanceHistoryEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            ProfileStrings.balanceHistoryEmptySubtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
