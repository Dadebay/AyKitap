import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/user_note.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/user_notes_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../book_detail/catalog_book_detail_screen.dart';
import 'widgets/edit_note_sheet.dart';
import 'widgets/note_card.dart';
import 'widgets/notes_delete_confirm_dialog.dart';
import 'widgets/notes_empty_state.dart';

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
    final image = note.bookImage;
    await context.pushHero(CatalogBookDetailScreen(
      bookId: note.bookId,
      heroTag: AppHeroTags.noteBookCover(note.id, note.bookId),
      initialCoverUrl: image != null && image.isNotEmpty
          ? ApiConfig.resolveImageUrl(image)
          : null,
    ));
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
      final updated =
          await UserNotesApiService.updateNote(note.id, note: draft.text);
      if (!mounted) return;
      setState(() =>
          _notes = _notes?.map((n) => n.id == note.id ? updated : n).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  Future<void> _deleteNote(UserNote note) async {
    final confirmed = await showDeleteNoteConfirmDialog(context);
    if (!confirmed) return;
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
        title: Text(ProfileStrings.notesTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
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
    final notes = _notes ?? const [];
    return notes.isEmpty
        ? const NotesEmptyState()
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
}
