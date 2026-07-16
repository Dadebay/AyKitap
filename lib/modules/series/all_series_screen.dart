import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock/mock_data.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/series_card.dart';
import '../../core/localization/strings/series_strings.dart';

/// Full catalogue behind the "Ählisi" button — every series stacked as big
/// cards, one per row.
class AllSeriesScreen extends StatelessWidget {
  const AllSeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final series = MockData.series;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        title: Text(SeriesStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: series.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => SizedBox(
            height: 200,
            child: SeriesCard(series: series[i]),
          ),
        ),
      ),
    );
  }
}
