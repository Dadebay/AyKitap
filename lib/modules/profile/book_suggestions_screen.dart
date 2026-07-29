import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/book_suggestion.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/feedback_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/profile_strings.dart';
import 'book_request_sheet.dart';
import 'widgets/book_suggestion_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(ProfileStrings.myBookRequestsTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(top: false, child: _buildBody()),
      bottomNavigationBar: _NewRequestBar(
        onPressed: _openRequestSheet,
        // A gentle breathing glow only while there's nothing else on the
        // page competing for attention — once requests exist the badge-y
        // pulse would just be noise next to them.
        pulse: !_loading && _error == null && (_suggestions ?? const []).isEmpty,
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
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(ProfileStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final suggestions = _suggestions ?? const [];
    if (suggestions.isEmpty) {
      final isDark = AppTheme.instance.isDark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    isDark ? 'assets/images/book_request_empty_dark.png' : 'assets/images/book_request_empty_light.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(ProfileStrings.noSuggestionsYet, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 15, height: 1.5)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => BookSuggestionCard(suggestion: suggestions[i]),
      ),
    );
  }
}

/// A bottom-docked bar rather than a floating pill — spans the full width
/// so it reads as "the" thing to do on this page, not a small extra option
/// tucked in a corner. Slides up on first appearance, gives a springy
/// press-down on tap, and — only while [pulse] is true, i.e. there's
/// nothing else on the page to draw the eye — breathes a soft glow above it
/// to nudge a first-time user toward it.
class _NewRequestBar extends StatefulWidget {
  final VoidCallback onPressed;
  final bool pulse;
  const _NewRequestBar({required this.onPressed, required this.pulse});

  @override
  State<_NewRequestBar> createState() => _NewRequestBarState();
}

class _NewRequestBarState extends State<_NewRequestBar> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _press;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1);
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    // A short beat after the page itself appears, not simultaneously — lets
    // the list/empty-state read first, then the bar slides in as its own beat.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _press.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    _press.animateTo(pressed ? 0.97 : 1, duration: Duration(milliseconds: pressed ? 100 : 220), curve: pressed ? Curves.easeOut : Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic)),
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _glow]),
        builder: (context, child) {
          final glowT = widget.pulse ? _glow.value : 0.0;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.12 + glowT * 0.14), blurRadius: 26 + glowT * 14, offset: const Offset(0, -8)),
              ],
            ),
            child: Transform.scale(
              scale: _press.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  onTapDown: (_) => _setPressed(true),
                  onTapUp: (_) => _setPressed(false),
                  onTapCancel: () => _setPressed(false),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35 + glowT * 0.25),
                          blurRadius: 16 + glowT * 12,
                          spreadRadius: glowT * 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(ProfileStrings.newBookRequest, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
