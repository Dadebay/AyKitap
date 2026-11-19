import 'dart:convert';

import 'package:aykitap/core/services/notes_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first load preserves queued deletes and serializes local edits',
      () async {
    SharedPreferences.setMockInitialValues({
      'reading_note_deletes_v1': jsonEncode([
        {'id': 42, 'owner': 7}
      ]),
    });

    final store = NotesStore.instance;
    await store.load();
    expect(store.pendingDeletionIdsFor(7), {42});

    final note =
        await store.add(text: 'first', bookId: 11, bookTitle: 'Local book');
    expect(note, isNotNull);
    await Future.wait([
      store.updateNote(note!.id, text: 'second'),
      store.updateNote(note.id, text: 'final'),
    ]);

    final prefs = await SharedPreferences.getInstance();
    final savedNotes =
        jsonDecode(prefs.getString('reading_notes_v1')!) as List<dynamic>;
    expect(savedNotes.singleWhere((entry) => entry['id'] == note.id)['text'],
        'final');
    expect(
      jsonDecode(prefs.getString('reading_note_deletes_v1')!),
      [
        {'id': 42, 'owner': 7}
      ],
    );
  });
}
