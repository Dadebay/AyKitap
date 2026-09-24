import 'package:dio/dio.dart';
import '../models/user_note.dart';
import '../network/account_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to `GET/POST /users/notes` and `PATCH/DELETE /users/notes/:id` —
/// backs Profile's "Notlar" list ([NotesScreen]).
class UserNotesApiService {
  UserNotesApiService._();

  static Future<List<UserNote>> getNotes() async {
    try {
      final response = await DioClient.instance.get(AccountEndpoints.userNotes);
      final items = response.data['data'] as List;
      return items
          .map((e) => UserNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<UserNote> createNote(
      {required int bookId, required String note, String? snippet}) async {
    try {
      final response =
          await DioClient.instance.post(AccountEndpoints.userNotes, data: {
        'book_id': bookId,
        'note': note,
        if (snippet != null) 'snippet': snippet,
      });
      return UserNote.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<UserNote> updateNote(int noteId,
      {String? note, String? snippet}) async {
    try {
      final response = await DioClient.instance
          .patch(AccountEndpoints.userNoteById(noteId), data: {
        if (note != null) 'note': note,
        if (snippet != null) 'snippet': snippet,
      });
      return UserNote.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<void> deleteNote(int noteId) async {
    try {
      await DioClient.instance.delete(AccountEndpoints.userNoteById(noteId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
