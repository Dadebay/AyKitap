import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The most frequently repeated [TextStyle] combinations across screens.
/// Getters (not fields) so they re-evaluate [AppColors] on every rebuild
/// after a dark/light switch, same reasoning as [AppColors] itself.
abstract final class AppTextStyles {
  static TextStyle get screenTitle => TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800);
  static TextStyle get sectionTitle => TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700);
  static TextStyle get sectionSubtitle => TextStyle(color: AppColors.grey2, fontSize: 12.5);
  static TextStyle get body => TextStyle(color: AppColors.grey2, fontSize: 14.5, height: 1.5);
  static TextStyle get label => TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600);
  static TextStyle get link => TextStyle(color: AppColors.primary, fontSize: 13);
}
