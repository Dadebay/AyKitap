import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../controller/filter_controller.dart';

/// The sticky "Netijeleri görkez" button — pops [FilterScreen] with the
/// controller's current [FilterController.buildResult].
class FilterBottomBar extends StatelessWidget {
  const FilterBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<FilterController>();
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context, c.buildResult()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(FilterStrings.showResults,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: Colors.white,
                  size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
