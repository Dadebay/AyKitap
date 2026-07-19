import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/models/reading_note.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/notes_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../book_detail/book_detail_screen.dart';
import 'widgets/edit_note_sheet.dart';
import 'widgets/note_card.dart';

/// "Ähli notlary gör" — TZ 8.4 (highlights/alyntylar): edit, delete, and
/// jump to the source book.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _store = NotesStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  void _goToBook(ReadingNote note) {
    final book = note.book;
    // Imported files have no catalogue entry to open — the card hides the
    // "go to book" affordance for them, but guard here too.
    if (book == null) return;
    context.push(BookDetailScreen(book: book));
  }

  Future<void> _editNote(ReadingNote note) async {
    final draft = await showModalBottomSheet<NoteDraft>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditNoteSheet(initialText: note.text, initialColor: note.colorValue),
    );
    if (draft == null || draft.text.isEmpty) return;
    await _store.updateNote(note.id, text: draft.text, colorValue: draft.colorValue);
  }

  Future<void> _deleteNote(ReadingNote note) async {
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
    if (confirmed == true) await _store.remove(note.id);
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesStore>().notes;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(ProfileStrings.notesTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: notes.isEmpty
          ? Center(child: Text(ProfileStrings.noNotesYet, style: TextStyle(color: AppColors.grey2, fontSize: 15)))
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
            ),
      ),
    );
  }
}
