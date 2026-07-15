import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/reading_note.dart';
import '../../core/services/notes_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../book_detail/book_detail_screen.dart';

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: note.book)));
  }

  Future<void> _editNote(ReadingNote note) async {
    final newText = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditNoteSheet(initialText: note.text),
    );
    if (newText == null || newText.isEmpty) return;
    await _store.updateText(note.id, newText);
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        centerTitle: true,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(ProfileStrings.notesTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final notes = _store.notes;
          if (notes.isEmpty) {
            return Center(child: Text(ProfileStrings.noNotesYet, style: TextStyle(color: AppColors.grey2, fontSize: 15)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _NoteCard(
              note: notes[i],
              onEdit: () => _editNote(notes[i]),
              onDelete: () => _deleteNote(notes[i]),
              onGoToBook: () => _goToBook(notes[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ReadingNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onGoToBook;
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete, required this.onGoToBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('“', style: TextStyle(color: AppColors.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(note.text, style: TextStyle(color: AppColors.grey1, fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.grey2, onTap: onEdit),
              const SizedBox(width: 8),
              _ActionIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.redAccent, onTap: onDelete),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onGoToBook,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(note.book.coverImage, width: 32, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ProfileStrings.goToBook, style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.primary, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Center(child: HugeIcon(icon: icon, color: color, size: 14)),
      ),
    );
  }
}

/// Full page-style bottom sheet for editing a note's text — matches
/// BookRequestSheet's layout (drag handle, icon header, card text field,
/// full-width primary action) instead of a cramped AlertDialog.
class _EditNoteSheet extends StatefulWidget {
  final String initialText;
  const _EditNoteSheet({required this.initialText});

  @override
  State<_EditNoteSheet> createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<_EditNoteSheet> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
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
                HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(ProfileStrings.editNoteTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text(ProfileStrings.editNoteSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: TextStyle(color: AppColors.white, fontSize: 14.5, height: 1.5),
                decoration: InputDecoration(hintText: ProfileStrings.noteTextHint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                onPressed: _save,
                child: Text(ProfileStrings.save, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ProfileStrings.cancel, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
