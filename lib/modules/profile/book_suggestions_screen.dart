import 'package:flutter/material.dart';
import '../../core/models/book_suggestion.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/feedback_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_strings.dart';
import 'book_request_sheet.dart';
import 'widgets/book_suggestion_card.dart';
import 'widgets/book_suggestions_empty_state.dart';
import 'widgets/new_book_request_bar.dart';

/// "Kitap haýyşlarym" — TZ 8.5's book-request flow plus its review status.
/// Lists what [BookRequestSheet] has sent for the signed-in account
/// (`GET /suggests/my`) as status-tagged cards, with the same sheet reused
/// behind the FAB to send another one.
class BookSuggestionsScreen extends StatefulWidget {
  const BookSuggestionsScreen({super.key});

  @override
  State<BookSuggestionsScreen> createState() => _BookSuggestionsScreenState();
}

class _BookSuggestionsScreenState extends State<BookSuggestionsScreen> {
  List<BookSuggestion>? _suggestions;
  final Set<int> _deletingIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suggestions = await FeedbackApiService.getMySuggestions();
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openRequestSheet() async {
    final sent = await BookRequestSheet.show(context);
    if (sent == true && mounted) _load();
  }

  Future<void> _deleteSuggestion(BookSuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ProfileStrings.deleteBookRequest,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800),
        ),
        content: Text(
          ProfileStrings.deleteBookRequestConfirm(suggestion.name),
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ProfileStrings.cancel,
                style: TextStyle(color: AppColors.grey2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ProfileStrings.delete,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(suggestion.id));
    try {
      await FeedbackApiService.deleteBookSuggestion(suggestion.id);
      if (!mounted) return;
      setState(() {
        _suggestions =
            _suggestions?.where((item) => item.id != suggestion.id).toList();
        _deletingIds.remove(suggestion.id);
      });
      context.showAppSnackBar(ProfileStrings.bookRequestDeleted);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(suggestion.id));
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(ProfileStrings.myBookRequestsTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(top: false, child: _buildBody()),
      bottomNavigationBar: NewBookRequestBar(
        onPressed: _openRequestSheet,
        // A gentle breathing glow only while there's nothing else on the
        // page competing for attention — once requests exist the badge-y
        // pulse would just be noise next to them.
        pulse:
            !_loading && _error == null && (_suggestions ?? const []).isEmpty,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load,
                  child: Text(ProfileStrings.retry,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final suggestions = _suggestions ?? const [];
    if (suggestions.isEmpty) {
      return const BookSuggestionsEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => BookSuggestionCard(
          suggestion: suggestions[i],
          isDeleting: _deletingIds.contains(suggestions[i].id),
          onDelete: () => _deleteSuggestion(suggestions[i]),
        ),
      ),
    );
  }
}
