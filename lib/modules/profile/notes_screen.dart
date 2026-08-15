import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/user_note.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/user_notes_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../book_detail/catalog_book_detail_screen.dart';
import 'widgets/edit_note_sheet.dart';
import 'widgets/note_card.dart';

/// "Ähli notlary gör" — every note/highlight the signed-in user has saved,
/// straight from `GET /users/notes` ([UserNotesApiService]). Used to be one
/// tab of a shared Notes/Bookmarks screen; the bookmarks half was removed
/// (bookmarking still exists per-book inside the reader itself), so this is
/// now the whole screen.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<UserNote>? _notes;
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
      final notes = await UserNotesApiService.getNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
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

  // This screen stays alive underneath the book detail page (it's a normal
  // push, not a replace), so nothing recreates it — and with it, nothing
  // reruns `initState`'s `_load()` — on the way back. A note added or
  // edited from inside the book (or its reader) would otherwise stay
  // invisible here until the list happened to reload some other way.
  // Reloading right after the push returns is the one moment this screen
  // reliably knows "the user might have just changed something".
  Future<void> _goToBook(UserNote note) async {
    await context.push(CatalogBookDetailScreen(bookId: note.bookId));
    if (mounted) _load();
  }

  Future<void> _editNote(UserNote note) async {
    final draft = await showModalBottomSheet<NoteDraft>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditNoteSheet(initialText: note.note),
    );
    if (draft == null || draft.text.isEmpty) return;
    try {
      final updated = await UserNotesApiService.updateNote(note.id, note: draft.text);
      if (!mounted) return;
      setState(() => _notes = _notes?.map((n) => n.id == note.id ? updated : n).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  Future<void> _deleteNote(UserNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.redAccent, size: 24)),
        ),
        title: Text(
          ProfileStrings.deleteNoteConfirmTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          ProfileStrings.actionIrreversible,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(ProfileStrings.delete, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(ProfileStrings.cancel, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Optimistic: remove immediately, roll back and surface the error if the
    // backend call fails.
    final previous = _notes;
    setState(() => _notes = _notes?.where((n) => n.id != note.id).toList());
    try {
      await UserNotesApiService.deleteNote(note.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _notes = previous);
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
        title: Text(ProfileStrings.notesTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(top: false, child: _buildBody()),
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
    final notes = _notes ?? const [];
    return notes.isEmpty
        ? _buildEmpty()
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => NoteCard(
              note: notes[i],
              onEdit: () => _editNote(notes[i]),
              onDelete: () => _deleteNote(notes[i]),
              onGoToBook: () => _goToBook(notes[i]),
            ),
          );
  }

  Widget _buildEmpty() {
    final isDark = AppTheme.instance.isDark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark ? 'assets/images/notes_empty_dark.webp' : 'assets/images/notes_empty_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              ProfileStrings.noNotesYetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              ProfileStrings.noNotesYetSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
