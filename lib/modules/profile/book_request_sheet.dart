import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/feedback_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_feedback_strings.dart';
import 'widgets/book_request_field.dart';
import 'widgets/book_request_language_chips.dart';
import 'widgets/book_request_submit_button.dart';

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
  String _language = ProfileFeedbackStrings.languageTurkmen;
  bool _sending = false;

  static List<String> get _languages => [
        ProfileFeedbackStrings.languageTurkmen,
        ProfileFeedbackStrings.languageTurkish,
        ProfileFeedbackStrings.languageRussian,
        ProfileFeedbackStrings.languageEnglish,
        ProfileFeedbackStrings.languageOther,
      ];

  // The sheet shows a localized label; the backend wants a stable code.
  String get _languageCode {
    if (_language == ProfileFeedbackStrings.languageTurkmen) return 'tk';
    if (_language == ProfileFeedbackStrings.languageTurkish) return 'tr';
    if (_language == ProfileFeedbackStrings.languageRussian) return 'ru';
    if (_language == ProfileFeedbackStrings.languageEnglish) return 'en';
    return 'other';
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _authorController.text.trim().isNotEmpty;

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
      context.showAppSnackBar(ProfileFeedbackStrings.bookRequestSentSuccess);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 18),
              Row(
                children: [
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedBookOpen01,
                      color: AppColors.primary,
                      size: 22),
                  SizedBox(width: 10),
                  Text(ProfileFeedbackStrings.bookRequestTitle,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              Text(ProfileFeedbackStrings.bookRequestSubtitle,
                  style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              const SizedBox(height: 20),
              BookRequestFieldLabel(ProfileFeedbackStrings.bookTitleLabel),
              BookRequestTextField(
                  controller: _titleController,
                  hint: ProfileFeedbackStrings.bookTitleHint,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              BookRequestFieldLabel(ProfileFeedbackStrings.authorNameLabel),
              BookRequestTextField(
                  controller: _authorController,
                  hint: ProfileFeedbackStrings.authorNameHint,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              BookRequestFieldLabel(ProfileFeedbackStrings.descriptionLabel),
              BookRequestTextField(
                  controller: _descriptionController,
                  hint: ProfileFeedbackStrings.descriptionHint,
                  maxLines: 3),
              const SizedBox(height: 14),
              BookRequestFieldLabel(ProfileFeedbackStrings.languageLabel),
              const SizedBox(height: 8),
              BookRequestLanguageChips(
                languages: _languages,
                selected: _language,
                onSelected: (l) => setState(() => _language = l),
              ),
              const SizedBox(height: 24),
              BookRequestSubmitButton(
                sending: _sending,
                onPressed: (_isValid && !_sending) ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
