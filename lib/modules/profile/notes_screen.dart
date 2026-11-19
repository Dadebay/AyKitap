import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/layout/adaptive_content_width.dart';
import '../../core/layout/two_column_layout.dart';

import '../../core/localization/strings/profile_strings.dart';
import '../../core/models/user_note.dart';
import '../../core/models/reading_note.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/user_notes_api_service.dart';
import '../../core/services/notes_store.dart';
import '../../core/services/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
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
  int? _ownerId;
  Map<int, ReadingNote> _localById = {};

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
    await NotesStore.instance.load();
    _ownerId = await AuthSession.getUserId();
    if (mounted) setState(() {});
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
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) => EditNoteSheet(initialText: note.note),
    );
    if (draft == null || draft.text.isEmpty) return;
    final local = _localById[note.id];
    if (local != null) {
      await NotesStore.instance.updateNote(local.id, text: draft.text);
      if (mounted) setState(() {});
      return;
    }
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
    final local = _localById[note.id];
    if (local != null) {
      await NotesStore.instance.remove(local.id);
      if (mounted) setState(() {});
      return;
    }
    // Optimistic: remove immediately, roll back and surface the error if the
    // backend call fails.
    final previous = _notes;
    setState(() => _notes = _notes?.where((n) => n.id != note.id).toList());
    try {
      await UserNotesApiService.deleteNote(note.id);
      await NotesStore.instance.removeSyncedLocal(note.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _notes = previous);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<NotesStore>();
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
      body: SafeArea(
          top: false,
          child: AdaptiveContentWidth(maxWidth: 1100, child: _buildBody())),
    );
  }

  Widget _buildBody() {
    final notes = _visibleNotes();
    if (_loading && notes.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && notes.isEmpty) {
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
    return notes.isEmpty
        ? const NotesEmptyState()
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TwoColumnList(
                itemCount: notes.length,
                itemBuilder: (_, i) => NoteCard(
                  note: notes[i],
                  onEdit: () => _editNote(notes[i]),
                  onDelete: () => _deleteNote(notes[i]),
                  onGoToBook: () => _goToBook(notes[i]),
                ),
              ),
            ],
          );
  }

  List<UserNote> _visibleNotes() {
    final owner = _ownerId;
    final deletedIds = owner == null
        ? const <int>{}
        : NotesStore.instance.pendingDeletionIdsFor(owner);
    final remote = (_notes ?? const <UserNote>[])
        .where((note) => !deletedIds.contains(note.id))
        .toList();
    final remoteIds = remote.map((n) => n.id).toSet();
    _localById = {};
    if (owner == null) return remote;
    final visible = <UserNote>[...remote];
    var localId = -1;
    for (final note in NotesStore.instance.notes) {
      if (note.ownerUserId != owner ||
          note.realBookId == null ||
          (note.remoteId != null && remoteIds.contains(note.remoteId))) {
        continue;
      }
      _localById[localId] = note;
      visible.add(UserNote(
        id: localId,
        note: note.text,
        snippet: note.snippet,
        bookId: note.realBookId!,
        bookName: note.bookTitle,
        createdAt: note.createdAt,
      ));
      localId--;
    }
    visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visible;
  }
}
