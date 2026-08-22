import 'package:flutter/material.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../main_nav/main_nav_screen.dart';

/// The "Baglanyşygy barla" / "Kitaphana" button pair at the bottom of
/// [OfflineLibraryScreen].
class OfflineLibraryActions extends StatelessWidget {
  final bool checking;
  final VoidCallback onCheckConnection;

  const OfflineLibraryActions(
      {super.key, required this.checking, required this.onCheckConnection});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: checking ? null : onCheckConnection,
              child: checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(LibraryStrings.checkConnection,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.grey3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const MainNavScreen(
                        initialIndex: 1, libraryInitialTabIndex: 2)),
              ),
              child: Text(LibraryStrings.goToLibrary,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
