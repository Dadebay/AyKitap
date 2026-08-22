import 'package:dio/dio.dart';
import '../network/book_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// `GET /books/file`'s `data` — a short-lived, presigned link to one of a
/// book's files on the media host.
///
/// [url] is signed with `X-Amz-Expires=600`, so it dies ~10 minutes after
/// it was issued. It is deliberately *not* persisted anywhere: every
/// download asks for a fresh one (see [BookDownloadService]).
class BookFileLink {
  final String url;
  final int size;
  final String name;
  final DateTime? lastModified;

  const BookFileLink({
    required this.url,
    required this.size,
    required this.name,
    this.lastModified,
  });

  factory BookFileLink.fromJson(Map<String, dynamic> json) => BookFileLink(
        url: json['url'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
      );
}

/// Resolves a [BookFile.fileKey] into something downloadable.
///
/// This call itself goes through [DioClient] (the API host, bearer token
/// attached) — it's the *download* of [BookFileLink.url] that must not,
/// since that URL is on the media host and its own signature is the
/// authorization; an extra `Authorization` header there can invalidate it.
class BookFileApiService {
  BookFileApiService._();

  /// GET `/books/file?filename={fileKey}`.
  static Future<BookFileLink> getFileLink(String fileKey) async {
    try {
      final response = await DioClient.instance.get(
        BookEndpoints.bookFile,
        queryParameters: {'filename': fileKey},
      );
      return BookFileLink.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
