import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/feedback_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_feedback_strings.dart';

/// Free-text bug/problem report, sent straight to `/problems`.
class ReportProblemSheet extends StatefulWidget {
  const ReportProblemSheet({super.key});

  @override
  State<ReportProblemSheet> createState() => _ReportProblemSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ReportProblemSheet(),
    );
  }
}

class _ReportProblemSheetState extends State<ReportProblemSheet> {
  static const _minLength = 10;
  static const _maxLength = 500;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  bool get _isValid => _controller.text.trim().length >= _minLength;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await FeedbackApiService.reportProblem(problem: _controller.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      context.showAppSnackBar(ProfileFeedbackStrings.reportProblemSentSuccess);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.trim().length;
    final showTooShortHint = length > 0 && length < _minLength;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grey3,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Center(
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedBug01,
                            color: AppColors.primary,
                            size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ProfileFeedbackStrings.reportProblemTitle,
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(ProfileFeedbackStrings.reportProblemSubtitle,
                            style: TextStyle(
                                color: AppColors.grey2,
                                fontSize: 12.5,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: showTooShortHint
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 5,
                  maxLength: _maxLength,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                      color: AppColors.white, fontSize: 14, height: 1.4),
                  decoration: InputDecoration(
                    hintText: ProfileFeedbackStrings.reportProblemHint,
                    hintStyle: TextStyle(color: AppColors.grey3),
                    border: InputBorder.none,
                    counterStyle:
                        TextStyle(color: AppColors.grey3, fontSize: 11.5),
                  ),
                ),
              ),
              if (showTooShortHint) ...[
                const SizedBox(height: 6),
                Text(ProfileFeedbackStrings.reportProblemTooShort,
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: (_isValid && !_sending) ? _submit : null,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(ProfileFeedbackStrings.send,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
