import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/feedback_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_strings.dart';

/// "Kitap Haýyşy" — TZ 8.5.
class BookRequestSheet extends StatefulWidget {
  const BookRequestSheet({super.key});

  @override
  State<BookRequestSheet> createState() => _BookRequestSheetState();

  /// Returns `true` if a request was actually sent — callers that show a
  /// list of the user's requests (e.g. [BookSuggestionsScreen]) use that to
  /// know when to refresh instead of reloading on every dismissal.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BookRequestSheet(),
    );
  }
}

class _BookRequestSheetState extends State<BookRequestSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _language = ProfileStrings.languageTurkmen;
  bool _sending = false;

  static List<String> get _languages => [
        ProfileStrings.languageTurkmen,
        ProfileStrings.languageTurkish,
        ProfileStrings.languageRussian,
        ProfileStrings.languageEnglish,
        ProfileStrings.languageOther,
      ];

  // The sheet shows a localized label; the backend wants a stable code.
  String get _languageCode {
    if (_language == ProfileStrings.languageTurkmen) return 'tk';
    if (_language == ProfileStrings.languageTurkish) return 'tr';
    if (_language == ProfileStrings.languageRussian) return 'ru';
    if (_language == ProfileStrings.languageEnglish) return 'en';
    return 'other';
  }

  bool get _isValid => _titleController.text.trim().isNotEmpty && _authorController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid || _sending) return;
    setState(() => _sending = true);
    try {
      await FeedbackApiService.createBookSuggestion(
        name: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        language: _languageCode,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      context.showAppSnackBar(ProfileStrings.bookRequestSentSuccess);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text(ProfileStrings.bookRequestTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              Text(ProfileStrings.bookRequestSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              const SizedBox(height: 20),
              _FieldLabel(ProfileStrings.bookTitleLabel),
              _TextField(controller: _titleController, hint: ProfileStrings.bookTitleHint, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              _FieldLabel(ProfileStrings.authorNameLabel),
              _TextField(controller: _authorController, hint: ProfileStrings.authorNameHint, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              _FieldLabel(ProfileStrings.descriptionLabel),
              _TextField(controller: _descriptionController, hint: ProfileStrings.descriptionHint, maxLines: 3),
              const SizedBox(height: 14),
              _FieldLabel(ProfileStrings.languageLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages.map((l) {
                  final selected = l == _language;
                  return GestureDetector(
                    onTap: () => setState(() => _language = l),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(l, style: TextStyle(color: selected ? Colors.white : AppColors.grey1, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: (_isValid && !_sending) ? _submit : null,
                  child: _sending
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(ProfileStrings.send, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _TextField({required this.controller, required this.hint, this.maxLines = 1, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxLines == 1 ? 50 : null,
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines == 1 ? 0 : 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none),
      ),
    );
  }
}
