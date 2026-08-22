import 'package:flutter/material.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/streak_strings.dart';
import 'widgets/streak_history_list.dart';
import 'widgets/streak_info_card.dart';
import 'widgets/streak_monthly_card.dart';
import 'widgets/streak_summary_card.dart';
import 'widgets/streak_week_card.dart';

/// Full-page view of the reading streak shown as a pill on HomeScreen —
/// same week grid as ProfileScreen's card, plus a per-day reading log
/// (pages + minutes) so a user can see exactly what they read and when.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    StreakService.instance.load();
    StreakService.instance.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(StreakStrings.title,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            StreakSummaryCard(),
            SizedBox(height: 16),
            StreakWeekCard(),
            SizedBox(height: 16),
            StreakMonthlyCard(),
            SizedBox(height: 16),
            StreakInfoCard(),
            SizedBox(height: 16),
            StreakHistoryList(),
          ],
        ),
      ),
    );
  }
}
